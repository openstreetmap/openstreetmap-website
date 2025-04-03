require "test_helper"

class NoteVersionTest < ActiveSupport::TestCase
  def test_content
    note_version = build(:note_version, :description => "Note's Description", :version => 5, :status => "closed")

    assert_equal "closed", note_version.status
    assert_equal 5, note_version.version
    assert_equal "Note's Description", note_version.description
  end
end
