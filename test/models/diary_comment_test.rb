require "test_helper"

class DiaryCommentTest < ActiveSupport::TestCase
  def test_diary_comment_exists
    comment = create(:diary_comment)
    assert_includes DiaryComment.all, comment
  end
end
