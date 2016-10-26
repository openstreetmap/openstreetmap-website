require "test_helper"

class DiaryCommentTest < ActiveSupport::TestCase
  fixtures :users

  def setup
    # Create the default language for diary entries
    create(:language, :code => "en")
  end

  test "body must be present" do
    comment = build(:diary_comment, :body => "")
    assert_not comment.valid?
    assert_not_nil comment.errors[:body], "no validation error for missing body"
  end
end
