require File.dirname(__FILE__) + '/../test_helper'

class DiaryEntryTest < Test::Unit::TestCase
  fixtures :diary_entries
  
  
  def test_diary_entry_count
    assert_equal 2, DiaryEntry.count
  end
  
end
