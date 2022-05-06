require "test_helper"

class IssueCommentTest < ActiveSupport::TestCase
  test "body must be present" do
    comment = build(:issue_comment, :body => "")
    assert_not comment.valid?
    assert_not_nil comment.errors[:body]
  end
end
