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

  test "revoke all page has no controls when viewed user has no active blocks" do
    blocked_user = create(:user)
    sign_in_as(create(:moderator_user))

    visit revoke_all_user_blocks_path(blocked_user)
    assert_title "Revoking all blocks on #{blocked_user.display_name}"
    assert_text "Revoking all blocks on #{blocked_user.display_name}"
    assert_no_button "Revoke!"
  end

  test "revoke all link is present and working for moderators when viewed user has one active block" do
    blocked_user = create(:user)
    create(:user_block, :user => blocked_user)
    sign_in_as(create(:moderator_user))

    visit user_path(blocked_user)
    assert_link "Revoke all blocks"

    click_on "Revoke all blocks"
    assert_title "Revoking all blocks on #{blocked_user.display_name}"
    assert_text "Revoking all blocks on #{blocked_user.display_name}"
    assert_unchecked_field "Are you sure you want to revoke 1 active block?"
    assert_button "Revoke!"
  end

  test "revoke all link is present and working for moderators when viewed user has multiple active blocks" do
    blocked_user = create(:user)
    create(:user_block, :user => blocked_user)
    create(:user_block, :user => blocked_user)
    create(:user_block, :expired, :user => blocked_user)
    sign_in_as(create(:moderator_user))

    visit user_path(blocked_user)
    assert_link "Revoke all blocks"

    click_on "Revoke all blocks"
    assert_title "Revoking all blocks on #{blocked_user.display_name}"
    assert_text "Revoking all blocks on #{blocked_user.display_name}"
    assert_unchecked_field "Are you sure you want to revoke 2 active blocks?"
    assert_button "Revoke!"
  end
end
