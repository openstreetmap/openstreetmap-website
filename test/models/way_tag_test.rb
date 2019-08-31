require "test_helper"

class WayTagTest < ActiveSupport::TestCase
  def test_length_key_valid
    tag = create(:way_tag)
    (0..255).each do |i|
      tag.k = "k" * i
      assert tag.valid?
    end
  end

  def test_length_value_valid
    tag = create(:way_tag)
    (0..255).each do |i|
      tag.v = "v" * i
      assert tag.valid?
    end
  end

  def test_length_key_invalid
    tag = create(:way_tag)
    tag.k = "k" * 256
    assert_not tag.valid?, "Key should be too long"
    assert tag.errors[:k].any?
  end

  def test_length_value_invalid
    tag = create(:way_tag)
    tag.v = "v" * 256
    assert_not tag.valid?, "Value should be too long"
    assert tag.errors[:v].any?
  end

  def test_empty_tag_invalid
    tag = WayTag.new
    assert_not tag.valid?, "Empty way tag should be invalid"
    assert tag.errors[:way].any?
  end

  def test_uniqueness
    existing = create(:way_tag)
    tag = WayTag.new
    tag.way_id = existing.way_id
    tag.k = existing.k
    tag.v = existing.v
    assert tag.new_record?
    assert_not tag.valid?
    assert_raise(ActiveRecord::RecordInvalid) { tag.save! }
    assert tag.new_record?
  end
end
