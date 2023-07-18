require "application_system_test_case"

class NoteCommentsTest < ApplicationSystemTestCase
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
