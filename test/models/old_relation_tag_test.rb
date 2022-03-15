require "test_helper"

class OldRelationTagTest < ActiveSupport::TestCase
  def test_length_key_valid
    tag = create(:old_relation_tag)
    [0, 255].each do |i|
      tag.k = "k" * i
      assert_predicate tag, :valid?
    end
  end

  def test_length_value_valid
    tag = create(:old_relation_tag)
    [0, 255].each do |i|
      tag.v = "v" * i
      assert_predicate tag, :valid?
    end
  end

  def test_length_key_invalid
    tag = create(:old_relation_tag)
    tag.k = "k" * 256
    assert_not tag.valid?, "Key should be too long"
    assert_predicate tag.errors[:k], :any?
  end

  def test_length_value_invalid
    tag = create(:old_relation_tag)
    tag.v = "v" * 256
    assert_not tag.valid?, "Value should be too long"
    assert_predicate tag.errors[:v], :any?
  end

  def test_empty_tag_invalid
    tag = OldRelationTag.new
    assert_not tag.valid?, "Empty tag should be invalid"
    assert_predicate tag.errors[:old_relation], :any?
  end

  def test_uniqueness
    existing = create(:old_relation_tag)
    tag = OldRelationTag.new
    tag.relation_id = existing.relation_id
    tag.version = existing.version
    tag.k = existing.k
    tag.v = existing.v
    assert_predicate tag, :new_record?
    assert_not tag.valid?
    assert_raise(ActiveRecord::RecordInvalid) { tag.save! }
    assert_predicate tag, :new_record?
  end
end
