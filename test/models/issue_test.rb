require "test_helper"

class IssueTest < ActiveSupport::TestCase
  def test_assigned_role
    issue = create(:issue)

    assert_predicate issue, :valid?
    issue.assigned_role = "bogus"
    assert_not_predicate issue, :valid?
  end

  def test_reported_user
    create(:language, :code => "en")
    user = create(:user)
    community = create(:community)
    note = create(:note_comment, :author => create(:user)).note
    anonymous_note = create(:note_comment, :author => nil).note
    diary_entry = create(:diary_entry)
    diary_comment = create(:diary_comment, :diary_entry => diary_entry)

    issue = build(:issue, :reportable => user, :assigned_role => "administrator")
    issue.save!
    assert_equal issue.reported_user, user

    issue = build(:issue, :reportable => community, :assigned_role => "moderator")
    issue.save!
    assert_equal issue.reported_user, community.leader

    issue = build(:issue, :reportable => note, :assigned_role => "administrator")
    issue.save!
    assert_equal issue.reported_user, note.author

    issue = build(:issue, :reportable => anonymous_note, :assigned_role => "administrator")
    issue.save!
    assert_nil issue.reported_user

    issue = build(:issue, :reportable => diary_entry, :assigned_role => "administrator")
    issue.save!
    assert_equal issue.reported_user, diary_entry.user

    issue = build(:issue, :reportable => diary_comment, :assigned_role => "administrator")
    issue.save!
    assert_equal issue.reported_user, diary_comment.user
  end
end
