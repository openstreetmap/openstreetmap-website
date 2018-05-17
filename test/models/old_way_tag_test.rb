require "test_helper"

class OldWayTagTest < ActiveSupport::TestCase
  def test_length_key_valid
    tag = create(:old_way_tag)
    (0..255).each do |i|
      tag.k = "k" * i
      assert tag.valid?
    end
  end

  def test_length_value_valid
    tag = create(:old_way_tag)
    (0..255).each do |i|
      tag.v = "v" * i
      assert tag.valid?
    end
  end

  def test_length_key_invalid
    tag = create(:old_way_tag)
    tag.k = "k" * 256
    assert !tag.valid?, "Key should be too long"
    assert tag.errors[:k].any?
  end

  def test_length_value_invalid
    tag = create(:old_way_tag)
    tag.v = "v" * 256
    assert !tag.valid?, "Value should be too long"
    assert tag.errors[:v].any?
  end

  def test_empty_tag_invalid
    tag = OldWayTag.new
    assert !tag.valid?, "Empty tag should be invalid"
    assert tag.errors[:old_way].any?
  end

  def test_uniqueness
    existing = create(:old_way_tag)
    tag = OldWayTag.new
    tag.way_id = existing.way_id
    tag.version = existing.version
    tag.k = existing.k
    tag.v = existing.v
    assert tag.new_record?
    assert_not tag.valid?
    assert_raise(ActiveRecord::RecordInvalid) { tag.save! }
    assert tag.new_record?
  end
end
