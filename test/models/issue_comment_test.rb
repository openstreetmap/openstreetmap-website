require "test_helper"

class IssueCommentTest < ActiveSupport::TestCase
  test "body must be present" do
    comment = build(:issue_comment, :body => "")
    assert_not comment.valid?
    assert_not_nil comment.errors[:body]
  end

  test "body" do
    comment = create(:issue_comment)
    assert_instance_of(RichText::Markdown, comment.body)
  end
end
