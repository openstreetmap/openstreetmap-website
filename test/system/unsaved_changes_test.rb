# frozen_string_literal: true

require "application_system_test_case"

class UnsavedChangesTest < ApplicationSystemTestCase
  def setup
    create(:language, :code => "en")
  end

  test "warn before leaving unsaved diary entry form" do
    user = create(:user)
    sign_in_as(user)

    visit new_diary_entry_path
    fill_in "Subject", :with => "A Diary Entry Title"
    fill_in "Body", :with => "This is the body."

    assert_selector "body[data-unsaved-changes]"
  end

  test "does not warn when publishing diary entry" do
    user = create(:user)
    sign_in_as(user)

    visit new_diary_entry_path
    fill_in "Subject", :with => "A Diary Entry Title"
    fill_in "Body", :with => "This is the body."

    assert_selector "body[data-unsaved-changes]"
    click_on "Publish"
    assert_no_selector "body[data-unsaved-changes]"

    assert_current_path diary_entry_path(user, DiaryEntry.last)
    assert_text "A Diary Entry Title"
  end

  test "warns before leaving unsaved message form" do
    sender = create(:user)
    recipient = create(:user)
    sign_in_as sender

    visit new_message_path(recipient)
    fill_in "Subject", :with => "A Message Title"

    assert_selector "body[data-unsaved-changes]"
  end

  test "message form does not warn before changes" do
    sender = create(:user)
    recipient = create(:user)
    sign_in_as sender

    visit new_message_path(recipient)
    assert_no_selector "body[data-unsaved-changes]"

    fill_in "Subject", :with => "A Message Title"
    fill_in "Body", :with => "A body"

    click_on "Send"

    assert_no_current_path new_message_path(recipient)
  end
end
