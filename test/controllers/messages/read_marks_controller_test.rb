require "test_helper"

module Messages
  class ReadMarksControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/messages/1/read_mark", :method => :post },
        { :controller => "messages/read_marks", :action => "create", :message_id => "1" }
      )
      assert_routing(
        { :path => "/messages/1/read_mark", :method => :delete },
        { :controller => "messages/read_marks", :action => "destroy", :message_id => "1" }
      )
    end

    def test_create_when_not_logged_in
      message = create(:message, :unread)

      post message_read_mark_path(message)
      assert_response :forbidden
    end

    def test_create_as_other_user
      message = create(:message, :unread)
      session_for(create(:user))

      post message_read_mark_path(message)
      assert_response :not_found
      assert_template "no_such_message"
    end

    def test_create_as_sender
      message = create(:message, :unread)
      session_for(message.sender)

      post message_read_mark_path(message)
      assert_response :not_found
      assert_template "no_such_message"
    end

    def test_create_as_recipient
      message = create(:message, :unread)
      session_for(message.recipient)

      post message_read_mark_path(message)
      assert_redirected_to messages_inbox_path
      assert message.reload.message_read
    end

    def test_create_on_missing_message
      session_for(create(:user))

      post message_read_mark_path(99999)
      assert_response :not_found
      assert_template "no_such_message"
    end

    def test_create_on_message_from_muted_user
      sender_user = create(:user)
      recipient_user = create(:user)
      create(:user_mute, :owner => recipient_user, :subject => sender_user)
      message = create(:message, :unread, :sender => sender_user, :recipient => recipient_user)
      session_for(recipient_user)

      post message_read_mark_path(message)
      assert_redirected_to messages_muted_inbox_path
      assert message.reload.message_read
    end

    def test_destroy_when_not_logged_in
      message = create(:message, :read)

      delete message_read_mark_path(message)
      assert_response :forbidden
    end

    def test_destroy_as_other_user
      message = create(:message, :read)
      session_for(create(:user))

      delete message_read_mark_path(message)
      assert_response :not_found
      assert_template "no_such_message"
    end

    def test_destroy_as_sender
      message = create(:message, :read)
      session_for(message.sender)

      delete message_read_mark_path(message)
      assert_response :not_found
      assert_template "no_such_message"
    end

    def test_destroy_as_recipient
      message = create(:message, :read)
      session_for(message.recipient)

      delete message_read_mark_path(message)
      assert_redirected_to messages_inbox_path
      assert_not message.reload.message_read
    end

    def test_destroy_on_missing_message
      session_for(create(:user))

      delete message_read_mark_path(99999)
      assert_response :not_found
      assert_template "no_such_message"
    end

    def test_destroy_on_message_from_muted_user
      sender_user = create(:user)
      recipient_user = create(:user)
      create(:user_mute, :owner => recipient_user, :subject => sender_user)
      message = create(:message, :read, :sender => sender_user, :recipient => recipient_user)
      session_for(recipient_user)

      delete message_read_mark_path(message, :mark => "unread")
      assert_redirected_to messages_muted_inbox_path
      assert_not message.reload.message_read
    end
  end
end
