require "application_system_test_case"

class ReportNoteTest < ApplicationSystemTestCase
  test "revoke all link is absent for anonymous users when viewed user has active blocks" do
    blocked_user = create(:user)
    create(:user_block, :user => blocked_user)

    visit user_path(blocked_user)
    assert_no_link "Revoke all blocks"
  end

  test "revoke all link is absent for regular users when viewed user has active blocks" do
    blocked_user = create(:user)
    create(:user_block, :user => blocked_user)
    sign_in_as(create(:user))

    visit user_path(blocked_user)
    assert_no_link "Revoke all blocks"
  end

  test "revoke all link is absent for moderators when viewed user has no active blocks" do
    blocked_user = create(:user)
    create(:user_block, :expired, :user => blocked_user)
    sign_in_as(create(:moderator_user))

    visit user_path(blocked_user)
    assert_no_link "Revoke all blocks"
  end

  test "revoke all link is present for moderators when viewed user has active blocks" do
    blocked_user = create(:user)
    create(:user_block, :user => blocked_user)
    sign_in_as(create(:moderator_user))

    visit user_path(blocked_user)
    assert_link "Revoke all blocks"
  end
end
