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

  test "can hide an open note as moderator" do
    note = create(:note_with_comments)
    user = create(:moderator_user)
    sign_in_as(user)
    visit note_path(note)

    within_sidebar do
      assert_button "Hide"

      click_on "Hide"

      assert_content "Hidden note ##{note.id}"
    end
  end

  test "can hide a closed note as moderator" do
    note = create(:note_with_comments, :closed)
    user = create(:moderator_user)
    sign_in_as(user)
    visit note_path(note)

    within_sidebar do
      assert_button "Hide"

      click_on "Hide"

      assert_content "Hidden note ##{note.id}"
      assert_no_content "<iframe" # leak from share textarea
    end
  end

  test "can't resolve a note when blocked" do
    note = create(:note_with_comments)
    user = create(:user)
    sign_in_as(user)
    visit note_path(note)
    create(:user_block, :user => user)

    within_sidebar do
      assert_text "Unresolved note"
      assert_no_text "Resolved note"
      assert_no_text "Your access to the API has been blocked"
      assert_button "Resolve", :disabled => false
      assert_button "Comment", :disabled => true

      click_on "Resolve"

      assert_text "Unresolved note"
      assert_no_text "Resolved note"
      assert_text "Your access to the API has been blocked"
      assert_button "Resolve", :disabled => false
      assert_button "Comment", :disabled => true
    end
  end

  test "can't reactivate a note when blocked" do
    note = create(:note_with_comments, :closed)
    user = create(:user)
    sign_in_as(user)
    visit note_path(note)
    create(:user_block, :user => user)

    within_sidebar do
      assert_no_text "Unresolved note"
      assert_text "Resolved note"
      assert_no_text "Your access to the API has been blocked"
      assert_button "Reactivate", :disabled => false

      click_on "Reactivate"

      assert_no_text "Unresolved note"
      assert_text "Resolved note"
      assert_text "Your access to the API has been blocked"
      assert_button "Reactivate", :disabled => false
    end
  end
end
