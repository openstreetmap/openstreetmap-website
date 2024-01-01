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
    note = create(:note_with_comments, :status => "closed", :closed_at => Time.now.utc)
    visit note_path(note)

    assert_no_button "Reactivate"
    assert_no_link "Log in to comment on this note"
  end

  def test_action_text
    note = create(:note_with_comments)
    sign_in_as(create(:user))
    visit note_path(note)

    assert_button "Resolve"
    assert_button "Comment", :disabled => true

    fill_in "text", :with => "Some text"

    assert_button "Comment & Resolve"
    assert_button "Comment"
  end
end
