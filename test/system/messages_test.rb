require "application_system_test_case"

class MessagesTest < ApplicationSystemTestCase
  def test_delete_received_message
    user = create(:user)
    create(:message, :recipient => user)
    sign_in_as(user)

    visit inbox_messages_path
    assert_text "You have 1 new message and 0 old messages"

    click_button "Delete"
    assert_text "You have 0 new messages and 0 old messages"
  end

  def test_delete_sent_message
    user = create(:user)
    create(:message, :sender => user)
    sign_in_as(user)

    visit outbox_messages_path
    assert_text "You have 1 sent message"

    click_button "Delete"
    assert_text "You have 0 sent messages"
  end

  def test_delete_muted_message
    user = create(:user)
    muted_user = create(:user)
    create(:user_mute, :owner => user, :subject => muted_user)
    create(:message, :sender => muted_user, :recipient => user)
    sign_in_as(user)

    visit muted_messages_path
    assert_text "1 muted message"

    click_button "Delete"
    assert_text "0 muted messages"
  end
end
