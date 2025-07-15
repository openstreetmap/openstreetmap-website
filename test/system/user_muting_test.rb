require "application_system_test_case"

class UserMutingTest < ApplicationSystemTestCase
  # NB: loads helpers to verify mailer-related behaviour e.g. via assert_no_emails
  include ActionMailer::TestHelper

  test "users can mute and unmute other users" do
    user = create(:user)
    other_user = create(:user)
    sign_in_as(user)

    visit user_path(other_user)
    click_on "Mute this User"
    assert_content "You muted #{other_user.display_name}"

    visit account_path
    assert_content "Muted Users"
    click_on "Muted Users"
    assert_content "You have muted 1 User"
    click_on "Unmute"

    assert_content "You unmuted #{other_user.display_name}"
    refute_content "Muted Users"
    assert_current_path account_path
  end

  test "messages sent by muted users are set `muted` and do not cause notification emails" do
    user = create(:user)
    muted_user = create(:user)
    create(:user_mute, :owner => user, :subject => muted_user)
    sign_in_as(muted_user)

    visit new_message_path(user)
    fill_in "Subject", :with => "Hey Hey"
    fill_in "Body", :with => "some message"

    assert_no_emails do
      click_on "Send"
    end

    message = Message.find_by(:sender => muted_user, :recipient => user)
    assert_predicate message, :muted?
  end
end
