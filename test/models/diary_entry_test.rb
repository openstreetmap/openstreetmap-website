require "test_helper"

class DiaryEntryTest < ActiveSupport::TestCase
  fixtures :users

  def setup
    # Create the default language for diary entries
    create(:language, :code => "en")
  end

  def test_diary_entry_validations
    diary_entry_valid({})
    diary_entry_valid({ :title => "" }, false)
    diary_entry_valid(:title => "a" * 255)
    diary_entry_valid({ :title => "a" * 256 }, false)
    diary_entry_valid({ :body => "" }, false)
    diary_entry_valid(:latitude => 90)
    diary_entry_valid({ :latitude => 90.00001 }, false)
    diary_entry_valid(:latitude => -90)
    diary_entry_valid({ :latitude => -90.00001 }, false)
    diary_entry_valid(:longitude => 180)
    diary_entry_valid({ :longitude => 180.00001 }, false)
    diary_entry_valid(:longitude => -180)
    diary_entry_valid({ :longitude => -180.00001 }, false)
  end

  def test_diary_entry_visible
    visible = create(:diary_entry)
    hidden = create(:diary_entry, :visible => false)
    assert_includes DiaryEntry.visible, visible
    assert_raise ActiveRecord::RecordNotFound do
      DiaryEntry.visible.find(hidden.id)
    end
  end

  def test_diary_entry_comments
    diary = create(:diary_entry)
    assert_equal(0, diary.comments.count)
    create(:diary_comment, :diary_entry => diary)
    assert_equal(1, diary.comments.count)
  end

  def test_diary_entry_visible_comments
    diary = create(:diary_entry)
    create(:diary_comment, :diary_entry => diary)
    create(:diary_comment, :diary_entry => diary, :visible => false)
    assert_equal 1, diary.visible_comments.count
    assert_equal 2, diary.comments.count
  end

  private

  def diary_entry_valid(attrs, result = true)
    entry = build(:diary_entry, attrs)
    assert_equal result, entry.valid?, "Expected #{attrs.inspect} to be #{result}"
  end
end
