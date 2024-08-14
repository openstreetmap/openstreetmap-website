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
end
