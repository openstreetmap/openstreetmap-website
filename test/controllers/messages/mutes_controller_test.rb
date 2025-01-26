require "test_helper"

module Messages
  class MutesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/messages/1/mute", :method => :delete },
        { :controller => "messages/mutes", :action => "destroy", :message_id => "1" }
      )
    end

    def test_destroy_when_not_logged_in
      sender_user = create(:user)
      recipient_user = create(:user)
      create(:user_mute, :owner => recipient_user, :subject => sender_user)
      message = create(:message, :unread, :sender => sender_user, :recipient => recipient_user)

      delete message_mute_path(message)
      assert_response :forbidden
    end

    def test_destroy_as_other_user
      sender_user = create(:user)
      recipient_user = create(:user)
      create(:user_mute, :owner => recipient_user, :subject => sender_user)
      message = create(:message, :unread, :sender => sender_user, :recipient => recipient_user)
      session_for(create(:user))

      delete message_mute_path(message)
      assert_response :not_found
      assert_template "no_such_message"
    end

    def test_destroy_as_sender
      sender_user = create(:user)
      recipient_user = create(:user)
      create(:user_mute, :owner => recipient_user, :subject => sender_user)
      message = create(:message, :unread, :sender => sender_user, :recipient => recipient_user)
      session_for(sender_user)

      delete message_mute_path(message)
      assert_response :not_found
      assert_template "no_such_message"
    end

    def test_destroy_as_recipient
      sender_user = create(:user)
      recipient_user = create(:user)
      create(:user_mute, :owner => recipient_user, :subject => sender_user)
      message = create(:message, :unread, :sender => sender_user, :recipient => recipient_user)
      session_for(recipient_user)

      delete message_mute_path(message)
      assert_redirected_to messages_inbox_path
      assert_not message.reload.muted
    end

    def test_destroy_on_missing_message
      session_for(create(:user))

      delete message_mute_path(99999)
      assert_response :not_found
      assert_template "no_such_message"
    end
  end
end
