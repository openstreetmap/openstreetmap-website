require "test_helper"

module Messages
  class InboxesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/messages/inbox", :method => :get },
        { :controller => "messages/inboxes", :action => "show" }
      )
    end

    def test_show
      user = create(:user)
      read_message = create(:message, :read, :recipient => user)

      session_for(user)

      get messages_inbox_path
      assert_response :success
      assert_select ".content-inner > table.messages-table > tbody", :count => 1 do
        assert_select "tr", :count => 1
        assert_select "tr#inbox-#{read_message.id}", :count => 1 do
          assert_select "a[href='#{user_path read_message.sender}']", :text => read_message.sender.display_name
          assert_select "a[href='#{message_path read_message}']", :text => read_message.title
        end
      end
    end

    def test_show_requires_login
      get messages_inbox_path
      assert_redirected_to login_path(:referer => messages_inbox_path)
    end
  end
end
