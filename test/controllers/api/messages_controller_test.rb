require "test_helper"

module Api
  class MessagesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
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
        { :path => "/api/0.6/user/messages/1", :method => :put },
        { :controller => "api/messages", :action => "update", :id => "1" }
      )
      assert_recognizes(
        { :controller => "api/messages", :action => "update", :id => "1" },
        { :path => "/api/0.6/user/messages/1", :method => :post }
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
      get api_message_path(msg)
      assert_response :unauthorized

      # only recipient and sender can read the message
      get api_message_path(msg), :headers => user3_auth
      assert_response :forbidden

      # message does not exist
      get api_message_path(99999), :headers => user3_auth
      assert_response :not_found

      # verify xml output
      get api_message_path(msg), :headers => recipient_auth
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
      get api_message_path(msg, :format => "json"), :headers => recipient_auth
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

      get api_message_path(msg), :headers => sender_auth
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
      get api_message_path(msg, :format => "json"), :headers => sender_auth
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

    def test_show_message_to_self_read
      user = create(:user)
      message = create(:message, :sender => user, :recipient => user)
      auth_header = bearer_authorization_header user

      get api_message_path(message), :headers => auth_header
      assert_response :success
      assert_equal "application/xml", response.media_type
      assert_dom "message", :count => 1 do
        assert_dom "> @message_read", "false"
      end
    end

    def test_show_message_to_self_read_json
      user = create(:user)
      message = create(:message, :sender => user, :recipient => user)
      auth_header = bearer_authorization_header user

      get api_message_path(message, :format => "json"), :headers => auth_header
      assert_response :success
      assert_equal "application/json", response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      jsm = js["message"]
      assert_not_nil jsm
      assert jsm.key?("message_read")
      assert_not jsm["message_read"]
    end

    def test_update_status
      recipient = create(:user)
      sender = create(:user)
      user3 = create(:user)

      recipient_auth = bearer_authorization_header(recipient, :scopes => %w[consume_messages])
      user3_auth = bearer_authorization_header(user3, :scopes => %w[send_messages consume_messages])

      msg = create(:message, :unread, :sender => sender, :recipient => recipient)

      # attempt to mark message as read by recipient, not authenticated
      put api_message_path(msg), :params => { :read_status => true }
      assert_response :unauthorized

      # attempt to mark message as read by recipient, not allowed
      put api_message_path(msg), :params => { :read_status => true }, :headers => user3_auth
      assert_response :forbidden

      # missing parameter
      put api_message_path(msg), :headers => recipient_auth
      assert_response :bad_request

      # wrong type of parameter
      put api_message_path(msg),
          :params => { :read_status => "not a boolean" },
          :headers => recipient_auth
      assert_response :bad_request

      # mark message as read by recipient
      put api_message_path(msg, :format => "json"),
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
      put api_message_path(msg, :format => "json"),
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
      delete api_message_path(msg)
      assert_response :unauthorized

      # attempt to delete message, by user3
      delete api_message_path(msg), :headers => user3_auth
      assert_response :forbidden

      # delete message by recipient
      delete api_message_path(msg, :format => "json"), :headers => recipient_auth
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
      delete api_message_path(msg, :format => "json"), :headers => sender_auth
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
  end
end
