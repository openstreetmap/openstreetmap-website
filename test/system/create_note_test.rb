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

  test "cannot create new note when zoomed out" do
    visit new_note_path(:anchor => "map=12/0/0")

    within_sidebar do
      assert_no_content "Zoom in to add a note"
      assert_button "Add Note", :disabled => true

      fill_in "text", :with => "Some newly added note description"

      assert_no_content "Zoom in to add a note"
      assert_button "Add Note", :disabled => false
    end

    find(".control-button.zoomout").click

    within_sidebar do
      assert_content "Zoom in to add a note"
      assert_button "Add Note", :disabled => true
    end

    find(".control-button.zoomin").click

    within_sidebar do
      assert_no_content "Zoom in to add a note"
      assert_button "Add Note", :disabled => false

      click_on "Add Note"

      assert_content "Unresolved note ##{Note.last.id}"
      assert_content "Some newly added note description"
    end
  end

  test "can open new note page when zoomed out" do
    visit new_note_path(:anchor => "map=11/0/0")

    within_sidebar do
      assert_content "Zoom in to add a note"
      assert_button "Add Note", :disabled => true

      fill_in "text", :with => "Some newly added note description"

      assert_content "Zoom in to add a note"
      assert_button "Add Note", :disabled => true
    end

    find(".control-button.zoomin").click

    within_sidebar do
      assert_no_content "Zoom in to add a note"
      assert_button "Add Note", :disabled => false
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
