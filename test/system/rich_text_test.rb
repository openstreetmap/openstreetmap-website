# frozen_string_literal: true

require "application_system_test_case"

class RichTextSystemTest < ApplicationSystemTestCase
  def setup
    create(:language, :code => "en")
  end

  test "switches to edit pane on validation failure" do
    sign_in_as create(:user)
    visit new_diary_entry_path
    fill_in "Subject", :with => "My Diary Entry Title"
    click_on "Preview"
    click_on "Publish"
    assert_field "Body"
  end

  test "arrow keys only cycle through the visible tabs" do
    sign_in_as create(:user)
    visit new_diary_entry_path

    edit_tab = find "button", :text => "Edit"
    edit_tab.send_keys :right
    assert_selector "button.active", :text => "Preview"

    find("button.active", :text => "Preview").send_keys :right
    assert_selector "button.active", :text => "Edit"
    assert_field "Body"
  end

  test "arrow keys include the help tab when it is visible" do
    original_size = page.current_window.size
    page.current_window.resize_to(500, 800)

    sign_in_as create(:user)
    visit new_diary_entry_path

    find("button", :text => "Edit").send_keys :left
    assert_selector "button.active", :text => "Help"
  ensure
    page.current_window.resize_to(*original_size) if original_size
  end
end
