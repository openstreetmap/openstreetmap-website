require "test_helper"

class UserMuteTest < ActiveSupport::TestCase
  def test_messages_by_muted_users_are_muted
    user = create(:user)
    muted_user = create(:user)
    create(:user_mute, :owner => user, :subject => muted_user)

    message = create(:message, :sender => muted_user, :recipient => user)
    assert_predicate message, :muted?
  end

  def test_messages_by_admins_or_moderators_are_never_muted
    user = create(:user)

    [create(:administrator_user), create(:moderator_user)].each do |admin_or_moderator|
      create(:user_mute, :owner => user, :subject => admin_or_moderator)

      message = create(:message, :sender => admin_or_moderator, :recipient => user)

      assert_not_predicate message, :muted?
    end
  end
end
