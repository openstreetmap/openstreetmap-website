require "application_system_test_case"

class CreateNoteTest < ApplicationSystemTestCase
  test "can create note" do
    visit new_note_path(:anchor => "map=18/0/0")

    within_sidebar do
      assert_button "Add Note", :disabled => true

      fill_in "text", :with => "Some newly added note description"
      click_on "Add Note"

      assert_content "Unresolved note ##{Note.last.id}"
      assert_content "Some newly added note description"
    end
  end

  test "cannot create note when api is readonly" do
    with_settings(:status => "api_readonly") do
      visit new_note_path(:anchor => "map=18/0/0")

      within_sidebar do
        assert_no_button "Add Note", :disabled => true
      end
    end
  end
end
