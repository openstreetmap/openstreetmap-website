require "application_system_test_case"

class NoteCommentsTest < ApplicationSystemTestCase
  test "open note has login notice" do
    note = create(:note_with_comments)
    visit note_path(note)

    assert_no_button "Resolve"
    assert_no_button "Comment"
    assert_link "Log in to comment on this note", :href => login_path(:referer => note_path(note))
  end

  test "closed note has no login notice" do
    note = create(:note_with_comments, :closed)
    visit note_path(note)

    assert_no_button "Reactivate"
    assert_no_link "Log in to comment on this note"
  end

  def test_add_comment
    note = create(:note_with_comments)
    user = create(:user)
    sign_in_as(user)
    visit note_path(note)

    assert_no_content "Comment from #{user.display_name}"
    assert_no_content "Some newly added note comment"
    assert_button "Resolve"
    assert_button "Comment", :disabled => true

    fill_in "text", :with => "Some newly added note comment"

    assert_button "Comment & Resolve"
    assert_button "Comment", :disabled => false

    click_button "Comment"

    assert_content "Comment from #{user.display_name}"
    assert_content "Some newly added note comment"
  end
end
