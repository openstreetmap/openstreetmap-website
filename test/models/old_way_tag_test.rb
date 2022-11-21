require "test_helper"

class OldWayTagTest < ActiveSupport::TestCase
  def test_length_key_valid
    tag = create(:old_way_tag)
    [0, 255].each do |i|
      tag.k = "k" * i
      assert_predicate tag, :valid?
    end
  end

  def test_length_value_valid
    tag = create(:old_way_tag)
    [0, 255].each do |i|
      tag.v = "v" * i
      assert_predicate tag, :valid?
    end
  end

  def test_length_key_invalid
    tag = create(:old_way_tag)
    tag.k = "k" * 256
    assert_not tag.valid?, "Key should be too long"
    assert_predicate tag.errors[:k], :any?
  end

  def test_length_value_invalid
    tag = create(:old_way_tag)
    tag.v = "v" * 256
    assert_not tag.valid?, "Value should be too long"
    assert_predicate tag.errors[:v], :any?
  end

  def test_orphaned_tag_invalid
    tag = create(:old_way_tag)
    tag.old_way = nil
    assert_not tag.valid?, "Orphaned tag should be invalid"
    assert_predicate tag.errors[:old_way], :any?
  end

  def test_uniqueness
    existing = create(:old_way_tag)
    tag = build(:old_way_tag, :old_way => existing.old_way, :version => existing.version, :k => existing.k, :v => existing.v)
    tag.way_id = existing.way_id
    tag.version = existing.version
    tag.k = existing.k
    tag.v = existing.v
    assert_predicate tag, :new_record?
    assert_not tag.valid?
    assert_raise(ActiveRecord::RecordInvalid) { tag.save! }
    assert_predicate tag, :new_record?
  end
end
