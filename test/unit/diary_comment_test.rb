require File.dirname(__FILE__) + '/../test_helper'

class DiaryCommentTest < Test::Unit::TestCase
  fixtures :diary_comments
  
  
  def test_diary_comment_count
    assert_equal 1, DiaryComment.count
  end
  
end
