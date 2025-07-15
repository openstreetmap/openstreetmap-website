require "application_system_test_case"

class UserBlocksSystemTest < ApplicationSystemTestCase
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

    visit edit_user_received_blocks_path(blocked_user)
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
    assert_unchecked_field "Are you sure you wish to revoke 1 active block?"
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
    assert_unchecked_field "Are you sure you wish to revoke 2 active blocks?"
    assert_button "Revoke!"
  end

  test "duration controls are present for active blocks" do
    creator_user = create(:moderator_user)
    block = create(:user_block, :creator => creator_user, :reason => "Testing editing active blocks", :ends_at => Time.now.utc + 2.days)
    sign_in_as(creator_user)

    visit edit_user_block_path(block)
    assert_field "Reason", :with => "Testing editing active blocks"
    assert_select "user_block_period", :selected => "2 days"
    assert_unchecked_field "Needs view"

    fill_in "Reason", :with => "Editing active blocks works"
    click_on "Update block"
    assert_text(/Reason for block:\s+Editing active blocks works/)
  end

  test "duration controls are removed for inactive blocks" do
    creator_user = create(:moderator_user)
    block = create(:user_block, :expired, :creator => creator_user, :reason => "Testing editing expired blocks")
    sign_in_as(creator_user)

    visit edit_user_block_path(block)
    assert_field "Reason", :with => "Testing editing expired blocks"
    assert_no_select "user_block_period"
    assert_no_field "Needs view"

    fill_in "Reason", :with => "Editing expired blocks works"
    click_on "Update block"
    assert_text(/Reason for block:\s+Editing expired blocks works/)
  end

  test "other moderator can revoke 0-hour blocks" do
    creator_user = create(:moderator_user)
    other_moderator_user = create(:moderator_user)
    block = create(:user_block, :zero_hour, :needs_view, :creator => creator_user, :reason => "Testing revoking 0-hour blocks")
    sign_in_as(other_moderator_user)

    visit edit_user_block_path(block)
    assert_field "Reason", :with => "Testing revoking 0-hour blocks"
    assert_no_select "user_block_period"
    assert_no_field "Needs view"

    fill_in "Reason", :with => "Revoking 0-hour blocks works"
    click_on "Revoke block"
    assert_text(/Revoker:\s+#{Regexp.escape other_moderator_user.display_name}/)
    assert_text(/Status:\s+Ended/)
    assert_text(/Reason for block:\s+Revoking 0-hour blocks works/)
  end
end
