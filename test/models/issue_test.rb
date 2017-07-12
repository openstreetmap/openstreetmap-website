require "test_helper"

class IssueTest < ActiveSupport::TestCase
  def test_reported_user
    note = create(:note_comment, :author => create(:user)).note
    user = create(:user)
    create(:language, :code => "en")
    diary_entry = create(:diary_entry)
    issue = Issue.new

    issue.reportable = user
    issue.save!
    assert_equal issue.reported_user, user

    # FIXME: doesn't handle anonymous notes
    issue.reportable = note
    issue.save!
    assert_equal issue.reported_user, note.author

    issue.reportable = diary_entry
    issue.save!
    assert_equal issue.reported_user, diary_entry.user
  end
end
