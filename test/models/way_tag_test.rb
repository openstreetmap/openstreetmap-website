require "test_helper"

class WayTagTest < ActiveSupport::TestCase
  api_fixtures

  def test_way_tag_count
    assert_equal 6, WayTag.count
  end

  def test_length_key_valid
    key = "k"
    (0..255).each do |i|
      tag = WayTag.new
      tag.way_id = current_way_tags(:t1).way_id
      tag.k = key * i
      tag.v = current_way_tags(:t1).v
      assert tag.valid?
    end
  end

  def test_length_value_valid
    val = "v"
    (0..255).each do |i|
      tag = WayTag.new
      tag.way_id = current_way_tags(:t1).way_id
      tag.k = "k"
      tag.v = val * i
      assert tag.valid?
    end
  end

  def test_length_key_invalid
    ["k" * 256].each do |i|
      tag = WayTag.new
      tag.way_id = current_way_tags(:t1).way_id
      tag.k = i
      tag.v = "v"
      assert !tag.valid?, "Key #{i} should be too long"
      assert tag.errors[:k].any?
    end
  end

  def test_length_value_invalid
    ["v" * 256].each do |i|
      tag = WayTag.new
      tag.way_id = current_way_tags(:t1).way_id
      tag.k = "k"
      tag.v = i
      assert !tag.valid?, "Value #{i} should be too long"
      assert tag.errors[:v].any?
    end
  end

  def test_empty_tag_invalid
    tag = WayTag.new
    assert !tag.valid?, "Empty way tag should be invalid"
    assert tag.errors[:way].any?
  end

  def test_uniqueness
    tag = WayTag.new
    tag.way_id = current_way_tags(:t1).way_id
    tag.k = current_way_tags(:t1).k
    tag.v = current_way_tags(:t1).v
    assert tag.new_record?
    assert !tag.valid?
    assert_raise(ActiveRecord::RecordInvalid) { tag.save! }
    assert tag.new_record?
  end
end
