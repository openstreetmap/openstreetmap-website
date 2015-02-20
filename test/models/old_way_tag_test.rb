require "test_helper"

class OldWayTagTest < ActiveSupport::TestCase
  api_fixtures

  def test_tag_count
    assert_equal 12, OldWayTag.count
  end

  def test_length_key_valid
    key = "k"
    (0..255).each do |i|
      tag = OldWayTag.new
      tag.way_id = way_tags(:t1).way_id
      tag.version = 1
      tag.k = key * i
      tag.v = "v"
      assert tag.valid?
    end
  end

  def test_length_value_valid
    val = "v"
    (0..255).each do |i|
      tag = OldWayTag.new
      tag.way_id = way_tags(:t1).way_id
      tag.version = 1
      tag.k = "k"
      tag.v = val * i
      assert tag.valid?
    end
  end

  def test_length_key_invalid
    ["k" * 256].each do |i|
      tag = OldWayTag.new
      tag.way_id = way_tags(:t1).way_id
      tag.version = 1
      tag.k = i
      tag.v = "v"
      assert !tag.valid?, "Key should be too long"
      assert tag.errors[:k].any?
    end
  end

  def test_length_value_invalid
    ["k" * 256].each do |i|
      tag = OldWayTag.new
      tag.way_id = way_tags(:t1).way_id
      tag.version = 1
      tag.k = "k"
      tag.v = i
      assert !tag.valid?, "Value should be too long"
      assert tag.errors[:v].any?
    end
  end

  def test_empty_tag_invalid
    tag = OldWayTag.new
    assert !tag.valid?, "Empty tag should be invalid"
    assert tag.errors[:old_way].any?
  end

  def test_uniqueness
    tag = OldWayTag.new
    tag.way_id = way_tags(:t1).way_id
    tag.version = way_tags(:t1).version
    tag.k = way_tags(:t1).k
    tag.v = way_tags(:t1).v
    assert tag.new_record?
    assert !tag.valid?
    assert_raise(ActiveRecord::RecordInvalid) { tag.save! }
    assert tag.new_record?
  end
end
