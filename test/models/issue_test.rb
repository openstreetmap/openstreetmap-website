require "test_helper"

class IssueTest < ActiveSupport::TestCase
  def test_assigned_role
    issue = create(:issue)

    assert issue.valid?
    issue.assigned_role = "bogus"
    assert_not issue.valid?
  end

  def test_reported_user
    create(:language, :code => "en")
    user = create(:user)
    note = create(:note_comment, :author => create(:user)).note
    anonymous_note = create(:note_comment, :author => nil).note
    diary_entry = create(:diary_entry)
    diary_comment = create(:diary_comment, :diary_entry => diary_entry)

    issue = Issue.new(:reportable => user, :assigned_role => "administrator")
    issue.save!
    assert_equal issue.reported_user, user

    issue = Issue.new(:reportable => note, :assigned_role => "administrator")
    issue.save!
    assert_equal issue.reported_user, note.author

    issue = Issue.new(:reportable => anonymous_note, :assigned_role => "administrator")
    issue.save!
    assert_nil issue.reported_user

    issue = Issue.new(:reportable => diary_entry, :assigned_role => "administrator")
    issue.save!
    assert_equal issue.reported_user, diary_entry.user

    issue = Issue.new(:reportable => diary_comment, :assigned_role => "administrator")
    issue.save!
    assert_equal issue.reported_user, diary_comment.user
  end
end
