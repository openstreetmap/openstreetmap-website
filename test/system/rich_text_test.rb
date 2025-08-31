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

  test "closing help hides card and expands editor" do
    sign_in_as create(:user)
    visit new_diary_entry_path

    # Ensure viewport is large enough such that Markdown guide is displayed next to textarea
    page.current_window.resize_to(800, 800)

    click_button(:class => "richtext_help_close")

    assert_no_selector "button.richtext_help_close", :visible => true
    assert_selector ".richtext_container .tab-content.col-sm-8[style*='width: 100%']"
  end
end
