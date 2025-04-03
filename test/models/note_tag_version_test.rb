require "test_helper"

class NoteTagVersionTest < ActiveSupport::TestCase
  def test_length_key_valid
    tag = create(:note_tag_version)
    [0, 255].each do |i|
      tag.k = "k" * i
      assert_predicate tag, :valid?
    end
  end

  def test_length_value_valid
    tag = create(:note_tag_version)
    [0, 255].each do |i|
      tag.v = "v" * i
      assert_predicate tag, :valid?
    end
  end

  def test_length_key_invalid
    tag = create(:note_tag_version)
    tag.k = "k" * 256
    assert_not_predicate tag, :valid?
    assert_predicate tag.errors[:k], :any?
  end

  def test_length_value_invalid
    tag = create(:note_tag_version)
    tag.v = "v" * 256
    assert_not_predicate tag, :valid?, "Value should be too long"
    assert_predicate tag.errors[:v], :any?
  end

  def test_orphaned_tag_invalid
    tag = create(:note_tag_version)
    tag.note_version = nil
    assert_not_predicate tag, :valid?, "Orphaned tag should be invalid"
    assert_predicate tag.errors[:note_version], :any?
  end

  def test_uniqueness
    existing = create(:note_tag_version)
    tag = build(:note_tag_version, :note_version => existing.note_version, :version => existing.version, :k => existing.k, :v => existing.v)
    assert_predicate tag, :new_record?
    assert_not_predicate tag, :valid?
    assert_raise(ActiveRecord::RecordInvalid) { tag.save! }
    assert_predicate tag, :new_record?
  end
end
