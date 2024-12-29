require "test_helper"

module Messages
  class OutboxesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/messages/outbox", :method => :get },
        { :controller => "messages/outboxes", :action => "show" }
      )
    end

    def test_show
      user = create(:user)
      message = create(:message, :sender => user)

      session_for(user)

      get messages_outbox_path
      assert_response :success
      assert_select ".content-inner > table.messages-table > tbody", :count => 1 do
        assert_select "tr", :count => 1
        assert_select "tr#outbox-#{message.id}", :count => 1 do
          assert_select "a[href='#{user_path message.recipient}']", :text => message.recipient.display_name
          assert_select "a[href='#{message_path message}']", :text => message.title
        end
      end
    end

    def test_show_requires_login
      get messages_outbox_path
      assert_redirected_to login_path(:referer => messages_outbox_path)
    end
  end
end
