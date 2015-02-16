require 'test_helper'

class DiaryEntryTest < ActiveSupport::TestCase
  api_fixtures
  fixtures :diary_entries, :diary_comments, :languages

  def test_diary_entry_count
    assert_equal 5, DiaryEntry.count
  end

  def test_diary_entry_validations
    diary_entry_valid({})
    diary_entry_valid({:title => ''}, false)
    diary_entry_valid({:title => 'a'*255})
    diary_entry_valid({:title => 'a'*256}, false)
    diary_entry_valid({:body => ''}, false)
    diary_entry_valid({:latitude => 90})
    diary_entry_valid({:latitude => 90.00001}, false)
    diary_entry_valid({:latitude => -90})
    diary_entry_valid({:latitude => -90.00001}, false)
    diary_entry_valid({:longitude => 180})
    diary_entry_valid({:longitude => 180.00001}, false)
    diary_entry_valid({:longitude => -180})
    diary_entry_valid({:longitude => -180.00001}, false)
  end

  def test_diary_entry_visible
    assert_equal 4, DiaryEntry.visible.count
    assert_raise ActiveRecord::RecordNotFound do
      DiaryEntry.visible.find(diary_entries(:deleted_entry).id)
    end
  end

  def test_diary_entry_comments
    assert_equal 0, diary_entries(:normal_user_entry_1).comments.count
    assert_equal 4, diary_entries(:normal_user_geo_entry).comments.count
  end

  def test_diary_entry_visible_comments
    assert_equal 0, diary_entries(:normal_user_entry_1).visible_comments.count
    assert_equal 1, diary_entries(:normal_user_geo_entry).visible_comments.count
  end

private

  def diary_entry_valid(attrs, result = true)
    entry = DiaryEntry.new(diary_entries(:normal_user_entry_1).attributes)
    entry.assign_attributes(attrs)
    assert_equal result, entry.valid?, "Expected #{attrs.inspect} to be #{result}"
  end
end
