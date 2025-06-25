require "test_helper"

module Messages
  class RepliesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/messages/1/reply/new", :method => :get },
        { :controller => "messages/replies", :action => "new", :message_id => "1" }
      )
    end

    def test_new
      user = create(:user)
      recipient_user = create(:user)
      other_user = create(:user)
      message = create(:message, :unread, :sender => user, :recipient => recipient_user)

      # Check that the message reply page requires us to login
      get new_message_reply_path(message)
      assert_redirected_to login_path(:referer => new_message_reply_path(message))

      # Login as the wrong user
      session_for(other_user)

      # Check that we can't reply to somebody else's message
      get new_message_reply_path(message)
      assert_redirected_to login_path(:referer => new_message_reply_path(message))
      assert_equal "You are logged in as '#{other_user.display_name}' but the message you have asked to reply to was not sent to that user. Please log in as the correct user in order to reply.", flash[:notice]

      # Login as the right user
      session_for(recipient_user)

      # Check that the message reply page loads
      get new_message_reply_path(message)
      assert_response :success
      assert_template "new"
      assert_select "title", "Re: #{message.title} | OpenStreetMap"
      assert_select "form[action='/messages']", :count => 1 do
        assert_select "input[type='hidden'][name='display_name'][value='#{user.display_name}']"
        assert_select "input#message_title[value='Re: #{message.title}']", :count => 1
        assert_select "textarea#message_body", :count => 1
        assert_select "input[type='submit'][value='Send']", :count => 1
      end
      assert Message.find(message.id).message_read

      # Login as the sending user
      session_for(user)

      # Check that the message reply page loads
      get new_message_reply_path(message)
      assert_response :success
      assert_template "new"
      assert_select "title", "Re: #{message.title} | OpenStreetMap"
      assert_select "form[action='/messages']", :count => 1 do
        assert_select "input[type='hidden'][name='display_name'][value='#{recipient_user.display_name}']"
        assert_select "input#message_title[value='Re: #{message.title}']", :count => 1
        assert_select "textarea#message_body", :count => 1
        assert_select "input[type='submit'][value='Send']", :count => 1
      end

      # Asking to reply to a message with a bogus ID should fail
      get new_message_reply_path(99999)
      assert_response :not_found
      assert_template "no_such_message"
    end
  end
end
