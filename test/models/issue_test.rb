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

  def test_default_assigned_role
    create(:language, :code => "en")
    diary_entry = create(:diary_entry)
    changeset = create(:changeset)

    issue = Issue.new
    issue.reportable = diary_entry
    issue.save!
    assert_equal "administrator", issue.assigned_role

    issue = Issue.new
    issue.reportable = changeset
    issue.save!
    assert_equal "moderator", issue.assigned_role

    # check the callback doesn't override an explicitly set role
    issue.assigned_role = "administrator"
    issue.save!
    issue.reload
    assert_equal "administrator", issue.assigned_role
  end
end
