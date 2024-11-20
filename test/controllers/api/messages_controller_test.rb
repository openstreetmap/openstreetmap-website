require "test_helper"

module Api
  class MessagesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/user/messages/inbox", :method => :get },
        { :controller => "api/messages", :action => "inbox" }
      )
      assert_routing(
        { :path => "/api/0.6/user/messages/inbox.xml", :method => :get },
        { :controller => "api/messages", :action => "inbox", :format => "xml" }
      )
      assert_routing(
        { :path => "/api/0.6/user/messages/inbox.json", :method => :get },
        { :controller => "api/messages", :action => "inbox", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/user/messages/outbox", :method => :get },
        { :controller => "api/messages", :action => "outbox" }
      )
      assert_routing(
        { :path => "/api/0.6/user/messages/outbox.xml", :method => :get },
        { :controller => "api/messages", :action => "outbox", :format => "xml" }
      )
      assert_routing(
        { :path => "/api/0.6/user/messages/outbox.json", :method => :get },
        { :controller => "api/messages", :action => "outbox", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/user/messages/1", :method => :get },
        { :controller => "api/messages", :action => "show", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/user/messages/1.xml", :method => :get },
        { :controller => "api/messages", :action => "show", :id => "1", :format => "xml" }
      )
      assert_routing(
        { :path => "/api/0.6/user/messages/1.json", :method => :get },
        { :controller => "api/messages", :action => "show", :id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/user/messages", :method => :post },
        { :controller => "api/messages", :action => "create" }
      )
      assert_routing(
        { :path => "/api/0.6/user/messages/1", :method => :post },
        { :controller => "api/messages", :action => "update", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/user/messages/1", :method => :delete },
        { :controller => "api/messages", :action => "destroy", :id => "1" }
      )
    end

    def test_create_success
      recipient = create(:user)
      sender = create(:user)

      sender_auth = bearer_authorization_header(sender, :scopes => %w[send_messages consume_messages])

      msg = build(:message)

      assert_difference "Message.count", 1 do
        assert_difference "ActionMailer::Base.deliveries.size", 1 do
          perform_enqueued_jobs do
            post api_messages_path,
                 :params => { :title => msg.title,
                              :recipient_id => recipient.id,
                              :body => msg.body,
                              :format => "json" },
                 :headers => sender_auth
            assert_response :success
          end
        end
      end

      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      jsm = js["message"]
      assert_not_nil jsm
      assert_not_nil jsm["id"]
      assert_equal sender.id, jsm["from_user_id"]
      assert_equal sender.display_name, jsm["from_display_name"]
      assert_equal recipient.id, jsm["to_user_id"]
      assert_equal recipient.display_name, jsm["to_display_name"]
      assert_equal msg.title, jsm["title"]
      assert_not_nil jsm["sent_on"]
      assert_equal !msg.from_user_visible, jsm["deleted"]
      assert_not jsm.key?("message_read")
      assert_equal "markdown", jsm["body_format"]
      assert_equal msg.body, jsm["body"]
    end

    def test_create_fail
      recipient = create(:user)

      sender = create(:user)
      sender_auth = bearer_authorization_header(sender, :scopes => %w[send_messages consume_messages])

      assert_no_difference "Message.count" do
        assert_no_difference "ActionMailer::Base.deliveries.size" do
          perform_enqueued_jobs do
            post api_messages_path,
                 :params => { :title => "Title",
                              :recipient_id => recipient.id,
                              :body => "body" }
          end
        end
      end
      assert_response :unauthorized

      assert_no_difference "Message.count" do
        assert_no_difference "ActionMailer::Base.deliveries.size" do
          perform_enqueued_jobs do
            post api_messages_path,
                 :params => { :recipient_id => recipient.id,
                              :body => "body" },
                 :headers => sender_auth
          end
        end
      end
      assert_response :bad_request

      assert_no_difference "Message.count" do
        assert_no_difference "ActionMailer::Base.deliveries.size" do
          perform_enqueued_jobs do
            post api_messages_path,
                 :params => { :title => "Title",
                              :body => "body" },
                 :headers => sender_auth
          end
        end
      end
      assert_response :bad_request

      assert_no_difference "Message.count" do
        assert_no_difference "ActionMailer::Base.deliveries.size" do
          perform_enqueued_jobs do
            post api_messages_path,
                 :params => { :title => "Title",
                              :recipient_id => recipient.id },
                 :headers => sender_auth
          end
        end
      end
      assert_response :bad_request
    end

    def test_show
      recipient = create(:user)
      sender = create(:user)
      user3 = create(:user)

      sender_auth = bearer_authorization_header(sender, :scopes => %w[consume_messages])
      recipient_auth = bearer_authorization_header(recipient, :scopes => %w[consume_messages])
      user3_auth = bearer_authorization_header(user3, :scopes => %w[send_messages consume_messages])

      msg = create(:message, :unread, :sender => sender, :recipient => recipient)

      # fail if not authorized
      get api_message_path(:id => msg.id)
      assert_response :unauthorized

      # only recipient and sender can read the message
      get api_message_path(:id => msg.id), :headers => user3_auth
      assert_response :forbidden

      # message does not exist
      get api_message_path(:id => 99999), :headers => user3_auth
      assert_response :not_found

      # verify xml output
      get api_message_path(:id => msg.id), :headers => recipient_auth
      assert_equal "application/xml", response.media_type
      assert_select "message", :count => 1 do
        assert_select "[id='#{msg.id}']"
        assert_select "[from_user_id='#{sender.id}']"
        assert_select "[from_display_name='#{sender.display_name}']"
        assert_select "[to_user_id='#{recipient.id}']"
        assert_select "[to_display_name='#{recipient.display_name}']"
        assert_select "[sent_on]"
        assert_select "[deleted='#{!msg.to_user_visible}']"
        assert_select "[message_read='#{msg.message_read}']"
        assert_select "[body_format='markdown']"
        assert_select "title", msg.title
        assert_select "body", msg.body
      end

      # verify json output
      get api_message_path(:id => msg.id, :format => "json"), :headers => recipient_auth
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      jsm = js["message"]
      assert_not_nil jsm
      assert_equal msg.id, jsm["id"]
      assert_equal sender.id, jsm["from_user_id"]
      assert_equal sender.display_name, jsm["from_display_name"]
      assert_equal recipient.id, jsm["to_user_id"]
      assert_equal recipient.display_name, jsm["to_display_name"]
      assert_equal msg.title, jsm["title"]
      assert_not_nil jsm["sent_on"]
      assert_equal msg.message_read, jsm["message_read"]
      assert_equal !msg.to_user_visible, jsm["deleted"]
      assert_equal "markdown", jsm["body_format"]
      assert_equal msg.body, jsm["body"]

      get api_message_path(:id => msg.id), :headers => sender_auth
      assert_equal "application/xml", response.media_type
      assert_select "message", :count => 1 do
        assert_select "[id='#{msg.id}']"
        assert_select "[from_user_id='#{sender.id}']"
        assert_select "[from_display_name='#{sender.display_name}']"
        assert_select "[to_user_id='#{recipient.id}']"
        assert_select "[to_display_name='#{recipient.display_name}']"
        assert_select "[sent_on]"
        assert_select "[deleted='#{!msg.from_user_visible}']"
        assert_select "[message_read='#{msg.message_read}']", 0
        assert_select "[body_format='markdown']"
        assert_select "title", msg.title
        assert_select "body", msg.body
      end

      # verify json output
      get api_message_path(:id => msg.id, :format => "json"), :headers => sender_auth
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      jsm = js["message"]
      assert_not_nil jsm
      assert_equal msg.id, jsm["id"]
      assert_equal sender.id, jsm["from_user_id"]
      assert_equal sender.display_name, jsm["from_display_name"]
      assert_equal recipient.id, jsm["to_user_id"]
      assert_equal recipient.display_name, jsm["to_display_name"]
      assert_equal msg.title, jsm["title"]
      assert_not_nil jsm["sent_on"]
      assert_equal !msg.from_user_visible, jsm["deleted"]
      assert_not jsm.key?("message_read")
      assert_equal "markdown", jsm["body_format"]
      assert_equal msg.body, jsm["body"]
    end

    def test_update_status
      recipient = create(:user)
      sender = create(:user)
      user3 = create(:user)

      recipient_auth = bearer_authorization_header(recipient, :scopes => %w[consume_messages])
      user3_auth = bearer_authorization_header(user3, :scopes => %w[send_messages consume_messages])

      msg = create(:message, :unread, :sender => sender, :recipient => recipient)

      # attempt to mark message as read by recipient, not authenticated
      post api_message_path(:id => msg.id), :params => { :read_status => true }
      assert_response :unauthorized

      # attempt to mark message as read by recipient, not allowed
      post api_message_path(:id => msg.id), :params => { :read_status => true }, :headers => user3_auth
      assert_response :forbidden

      # missing parameter
      post api_message_path(:id => msg.id), :headers => recipient_auth
      assert_response :bad_request

      # wrong type of parameter
      post api_message_path(:id => msg.id),
           :params => { :read_status => "not a boolean" },
           :headers => recipient_auth
      assert_response :bad_request

      # mark message as read by recipient
      post api_message_path(:id => msg.id, :format => "json"),
           :params => { :read_status => true },
           :headers => recipient_auth
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      jsm = js["message"]
      assert_not_nil jsm
      assert_equal msg.id, jsm["id"]
      assert_equal sender.id, jsm["from_user_id"]
      assert_equal sender.display_name, jsm["from_display_name"]
      assert_equal recipient.id, jsm["to_user_id"]
      assert_equal recipient.display_name, jsm["to_display_name"]
      assert_equal msg.title, jsm["title"]
      assert_not_nil jsm["sent_on"]
      assert jsm["message_read"]
      assert_equal !msg.to_user_visible, jsm["deleted"]
      assert_equal "markdown", jsm["body_format"]
      assert_equal msg.body, jsm["body"]

      # mark message as unread by recipient
      post api_message_path(:id => msg.id, :format => "json"),
           :params => { :read_status => false },
           :headers => recipient_auth
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      jsm = js["message"]
      assert_not_nil jsm
      assert_equal msg.id, jsm["id"]
      assert_equal sender.id, jsm["from_user_id"]
      assert_equal sender.display_name, jsm["from_display_name"]
      assert_equal recipient.id, jsm["to_user_id"]
      assert_equal recipient.display_name, jsm["to_display_name"]
      assert_equal msg.title, jsm["title"]
      assert_not_nil jsm["sent_on"]
      assert_not jsm["message_read"]
      assert_equal !msg.to_user_visible, jsm["deleted"]
      assert_equal "markdown", jsm["body_format"]
      assert_equal msg.body, jsm["body"]
    end

    def test_delete
      recipient = create(:user)
      recipient_auth = bearer_authorization_header(recipient, :scopes => %w[consume_messages])

      sender = create(:user)
      sender_auth = bearer_authorization_header(sender, :scopes => %w[send_messages consume_messages])

      user3 = create(:user)
      user3_auth = bearer_authorization_header(user3, :scopes => %w[send_messages consume_messages])

      msg = create(:message, :read, :sender => sender, :recipient => recipient)

      # attempt to delete message, not authenticated
      delete api_message_path(:id => msg.id)
      assert_response :unauthorized

      # attempt to delete message, by user3
      delete api_message_path(:id => msg.id), :headers => user3_auth
      assert_response :forbidden

      # delete message by recipient
      delete api_message_path(:id => msg.id, :format => "json"), :headers => recipient_auth
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      jsm = js["message"]
      assert_not_nil jsm
      assert_equal msg.id, jsm["id"]
      assert_equal sender.id, jsm["from_user_id"]
      assert_equal sender.display_name, jsm["from_display_name"]
      assert_equal recipient.id, jsm["to_user_id"]
      assert_equal recipient.display_name, jsm["to_display_name"]
      assert_equal msg.title, jsm["title"]
      assert_not_nil jsm["sent_on"]
      assert_equal msg.message_read, jsm["message_read"]
      assert jsm["deleted"]
      assert_equal "markdown", jsm["body_format"]
      assert_equal msg.body, jsm["body"]

      # delete message by sender
      delete api_message_path(:id => msg.id, :format => "json"), :headers => sender_auth
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      jsm = js["message"]
      assert_not_nil jsm
      assert_equal msg.id, jsm["id"]
      assert_equal sender.id, jsm["from_user_id"]
      assert_equal sender.display_name, jsm["from_display_name"]
      assert_equal recipient.id, jsm["to_user_id"]
      assert_equal recipient.display_name, jsm["to_display_name"]
      assert_equal msg.title, jsm["title"]
      assert_not_nil jsm["sent_on"]
      assert jsm["deleted"]
      assert_not jsm.key?("message_read")
      assert_equal "markdown", jsm["body_format"]
      assert_equal msg.body, jsm["body"]
    end

    def test_list_messages
      user1 = create(:user)
      user1_auth = bearer_authorization_header(user1, :scopes => %w[send_messages consume_messages])

      user2 = create(:user)
      user2_auth = bearer_authorization_header(user2, :scopes => %w[send_messages consume_messages])

      user3 = create(:user)
      user3_auth = bearer_authorization_header(user3, :scopes => %w[send_messages consume_messages])

      # create some messages between users
      # user | inbox | outbox
      #   1  |   0   |   3
      #   2  |   2   |   1
      #   3  |   2   |   0
      create(:message, :unread, :sender => user1, :recipient => user2)
      create(:message, :unread, :sender => user1, :recipient => user2)
      create(:message, :unread, :sender => user1, :recipient => user3)
      create(:message, :unread, :sender => user2, :recipient => user3)

      # only authorized users
      get inbox_api_messages_path
      assert_response :unauthorized
      get outbox_api_messages_path
      assert_response :unauthorized

      # no messages in user1.inbox
      get inbox_api_messages_path, :headers => user1_auth
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "message", :count => 0

      # 3 messages in user1.outbox
      get outbox_api_messages_path, :headers => user1_auth
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "message", :count => 3 do
        assert_select "[from_user_id='#{user1.id}']"
        assert_select "[from_display_name='#{user1.display_name}']"
        assert_select "[to_user_id]"
        assert_select "[to_display_name]"
        assert_select "[sent_on]"
        assert_select "[message_read]", 0
        assert_select "[deleted='false']"
        assert_select "[body_format]"
        assert_select "body", false
        assert_select "title"
      end

      # 2 messages in user2.inbox
      get inbox_api_messages_path, :headers => user2_auth
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "message", :count => 2 do
        assert_select "[from_user_id]"
        assert_select "[from_display_name]"
        assert_select "[to_user_id='#{user2.id}']"
        assert_select "[to_display_name='#{user2.display_name}']"
        assert_select "[sent_on]"
        assert_select "[message_read='false']"
        assert_select "[deleted='false']"
        assert_select "[body_format]"
        assert_select "body", false
        assert_select "title"
      end

      # 1 message in user2.outbox
      get outbox_api_messages_path, :headers => user2_auth
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "message", :count => 1 do
        assert_select "[from_user_id='#{user2.id}']"
        assert_select "[from_display_name='#{user2.display_name}']"
        assert_select "[to_user_id]"
        assert_select "[to_display_name]"
        assert_select "[sent_on]"
        assert_select "[deleted='false']"
        assert_select "[message_read]", 0
        assert_select "[body_format]"
        assert_select "body", false
        assert_select "title"
      end

      # 2 messages in user3.inbox
      get inbox_api_messages_path, :headers => user3_auth
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "message", :count => 2 do
        assert_select "[from_user_id]"
        assert_select "[from_display_name]"
        assert_select "[to_user_id='#{user3.id}']"
        assert_select "[to_display_name='#{user3.display_name}']"
        assert_select "[sent_on]"
        assert_select "[message_read='false']"
        assert_select "[deleted='false']"
        assert_select "[body_format]"
        assert_select "body", false
        assert_select "title"
      end

      # 0 messages in user3.outbox
      get outbox_api_messages_path, :headers => user3_auth
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_select "message", :count => 0
    end

    def test_paged_list_messages_asc
      recipient = create(:user)
      recipient_auth = bearer_authorization_header(recipient, :scopes => %w[consume_messages])

      sender = create(:user)

      create_list(:message, 100, :unread, :sender => sender, :recipient => recipient)

      msgs_read = {}
      params = { :order => "oldest", :limit => 20 }
      10.times do
        get inbox_api_messages_path(:format => "json"),
            :params => params,
            :headers => recipient_auth
        assert_response :success
        assert_equal "application/json", response.media_type
        js = ActiveSupport::JSON.decode(@response.body)
        jsm = js["messages"]
        assert_operator jsm.count, :<=, 20

        break if jsm.nil? || jsm.count.zero?

        assert_operator(jsm[0]["id"], :>=, params[:from_id]) unless params[:from_id].nil?
        # ensure ascending order
        (0..jsm.count - 1).each do |i|
          assert_operator(jsm[i]["id"], :<, jsm[i + 1]["id"]) unless i == jsm.count - 1
          msgs_read[jsm[i]["id"]] = jsm[i]
        end
        params[:from_id] = jsm[jsm.count - 1]["id"]
      end
      assert_equal 100, msgs_read.count
    end

    def test_paged_list_messages_desc
      recipient = create(:user)
      recipient_auth = bearer_authorization_header(recipient, :scopes => %w[consume_messages])

      sender = create(:user)

      create_list(:message, 100, :unread, :sender => sender, :recipient => recipient)

      real_max_id = -1
      msgs_read = {}
      params = { :order => "newest", :limit => 20 }
      10.times do
        get inbox_api_messages_path(:format => "json"),
            :params => params,
            :headers => recipient_auth
        assert_response :success
        assert_equal "application/json", response.media_type
        js = ActiveSupport::JSON.decode(@response.body)
        jsm = js["messages"]
        assert_operator jsm.count, :<=, 20

        break if jsm.nil? || jsm.count.zero?

        if params[:from_id].nil?
          real_max_id = jsm[0]["id"]
        else
          assert_operator jsm[0]["id"], :<=, params[:from_id]
        end
        # ensure descending order
        (0..jsm.count - 1).each do |i|
          assert_operator(jsm[i]["id"], :>, jsm[i + 1]["id"]) unless i == jsm.count - 1
          msgs_read[jsm[i]["id"]] = jsm[i]
        end
        params[:from_id] = jsm[jsm.count - 1]["id"]
      end
      assert_equal 100, msgs_read.count
      assert_not_equal(-1, real_max_id)

      # invoke without min_id/max_id parameters, verify that we get the last batch
      get inbox_api_messages_path(:format => "json"), :params => { :limit => 20 }, :headers => recipient_auth
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      jsm = js["messages"]
      assert_not_nil jsm
      assert_equal real_max_id, jsm[0]["id"]
    end
  end
end
