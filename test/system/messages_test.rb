require "application_system_test_case"

class MessagesTest < ApplicationSystemTestCase
  def test_delete_received_message
    user = create(:user)
    create(:message, :recipient => user)
    sign_in_as(user)

    visit messages_inbox_path
    assert_text "You have 1 new message and 0 old messages"

    click_on "Delete"
    assert_text "You have 0 new messages and 0 old messages"
  end

  def test_delete_sent_message
    user = create(:user)
    create(:message, :sender => user)
    sign_in_as(user)

    visit messages_outbox_path
    assert_text "You have 1 sent message"

    click_on "Delete"
    assert_text "You have 0 sent messages"
  end

  def test_delete_muted_message
    user = create(:user)
    muted_user = create(:user)
    create(:user_mute, :owner => user, :subject => muted_user)
    create(:message, :sender => muted_user, :recipient => user)
    sign_in_as(user)

    visit messages_muted_inbox_path
    assert_text "1 muted message"

    click_on "Delete"
    refute_text "1 muted message"
    assert_text "You have 0 new messages and 0 old messages"
  end
end
