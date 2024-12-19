require "application_system_test_case"

class ResolveNoteTest < ApplicationSystemTestCase
  test "can resolve an open note" do
    note = create(:note_with_comments)
    user = create(:user)
    sign_in_as(user)
    visit note_path(note)

    within_sidebar do
      assert_button "Resolve"
      assert_no_button "Comment & Resolve"
      assert_no_button "Reactivate"

      click_on "Resolve"

      assert_content "Resolved note ##{note.id}"
    end
  end

  test "can resolve an open note with a comment" do
    note = create(:note_with_comments)
    user = create(:user)
    sign_in_as(user)
    visit note_path(note)

    within_sidebar do
      assert_button "Resolve"
      assert_no_button "Comment & Resolve"
      assert_no_button "Reactivate"

      fill_in "text", :with => "Note resolve text"

      assert_button "Comment & Resolve"

      click_on "Comment & Resolve"

      assert_content "Resolved note ##{note.id}"
      assert_content "Note resolve text"
    end
  end

  test "can reactivate a closed note" do
    note = create(:note_with_comments, :closed)
    user = create(:user)
    sign_in_as(user)
    visit note_path(note)

    within_sidebar do
      assert_no_button "Resolve"
      assert_no_button "Comment & Resolve"
      assert_button "Reactivate"

      click_on "Reactivate"

      assert_content "Unresolved note ##{note.id}"
      assert_no_content "<iframe" # leak from share textarea
    end
  end
end
