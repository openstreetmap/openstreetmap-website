require "test_helper"

module Api
  module Messages
    class InboxesControllerTest < ActionDispatch::IntegrationTest
      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/user/messages/inbox", :method => :get },
          { :controller => "api/messages/inboxes", :action => "show" }
        )
        assert_routing(
          { :path => "/api/0.6/user/messages/inbox.xml", :method => :get },
          { :controller => "api/messages/inboxes", :action => "show", :format => "xml" }
        )
        assert_routing(
          { :path => "/api/0.6/user/messages/inbox.json", :method => :get },
          { :controller => "api/messages/inboxes", :action => "show", :format => "json" }
        )
      end

      def test_show
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
        get api_messages_inbox_path
        assert_response :unauthorized

        # no messages in user1.inbox
        get api_messages_inbox_path, :headers => user1_auth
        assert_response :success
        assert_equal "application/xml", response.media_type
        assert_select "message", :count => 0

        # 2 messages in user2.inbox
        get api_messages_inbox_path, :headers => user2_auth
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

        # 2 messages in user3.inbox
        get api_messages_inbox_path, :headers => user3_auth
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
      end

      def test_show_paged_asc
        recipient = create(:user)
        recipient_auth = bearer_authorization_header(recipient, :scopes => %w[consume_messages])

        sender = create(:user)

        create_list(:message, 100, :unread, :sender => sender, :recipient => recipient)

        msgs_read = {}
        params = { :order => "oldest", :limit => 20 }
        10.times do
          get api_messages_inbox_path(:format => "json"),
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

      def test_show_paged_desc
        recipient = create(:user)
        recipient_auth = bearer_authorization_header(recipient, :scopes => %w[consume_messages])

        sender = create(:user)

        create_list(:message, 100, :unread, :sender => sender, :recipient => recipient)

        real_max_id = -1
        msgs_read = {}
        params = { :order => "newest", :limit => 20 }
        10.times do
          get api_messages_inbox_path(:format => "json"),
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
        get api_messages_inbox_path(:format => "json"), :params => { :limit => 20 }, :headers => recipient_auth
        assert_response :success
        assert_equal "application/json", response.media_type
        js = ActiveSupport::JSON.decode(@response.body)
        jsm = js["messages"]
        assert_not_nil jsm
        assert_equal real_max_id, jsm[0]["id"]
      end
    end
  end
end
