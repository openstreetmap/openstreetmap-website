require "test_helper"

module Api
  module Messages
    class OutboxesControllerTest < ActionDispatch::IntegrationTest
      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/user/messages/outbox", :method => :get },
          { :controller => "api/messages/outboxes", :action => "show" }
        )
        assert_routing(
          { :path => "/api/0.6/user/messages/outbox.xml", :method => :get },
          { :controller => "api/messages/outboxes", :action => "show", :format => "xml" }
        )
        assert_routing(
          { :path => "/api/0.6/user/messages/outbox.json", :method => :get },
          { :controller => "api/messages/outboxes", :action => "show", :format => "json" }
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
        get api_messages_outbox_path
        assert_response :unauthorized

        # 3 messages in user1.outbox
        get api_messages_outbox_path, :headers => user1_auth
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

        # 1 message in user2.outbox
        get api_messages_outbox_path, :headers => user2_auth
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

        # 0 messages in user3.outbox
        get api_messages_outbox_path, :headers => user3_auth
        assert_response :success
        assert_equal "application/xml", response.media_type
        assert_select "message", :count => 0
      end
    end
  end
end
