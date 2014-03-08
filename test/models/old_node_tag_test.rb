require 'test_helper'

class OldNodeTagTest < ActiveSupport::TestCase
  api_fixtures

  def test_old_node_tag_count
    assert_equal 19, OldNodeTag.count, "Unexpected number of fixtures loaded."
  end
  
  def test_length_key_valid
    key = "k"
    (0..255).each do |i|
      tag = OldNodeTag.new
      tag.node_id = node_tags(:t1).node_id
      tag.version = node_tags(:t1).version
      tag.k = key*i
      tag.v = "v"
      assert tag.valid?
    end
  end
  
  def test_length_value_valid
    val = "v"
    (0..255).each do |i|
      tag = OldNodeTag.new
      tag.node_id = node_tags(:t1).node_id
      tag.version = node_tags(:t1).version
      tag.k = "k"
      tag.v = val*i
      assert tag.valid?
    end
  end
  
  def test_length_key_invalid
    ["k"*256].each do |i|
      tag = OldNodeTag.new
      tag.node_id = node_tags(:t1).node_id
      tag.version = node_tags(:t1).version
      tag.k = i
      tag.v = "v", "Key should be too long"
      assert !tag.valid?
      assert tag.errors[:k].any?
    end
  end
  
  def test_length_value_invalid
    ["k"*256].each do |i|
      tag = OldNodeTag.new
      tag.node_id = node_tags(:t1).node_id
      tag.version = node_tags(:t1).version
      tag.k = "k"
      tag.v = i
      assert !tag.valid?, "Value should be too long"
      assert tag.errors[:v].any?
    end
  end
  
  def test_empty_tag_invalid
    tag = OldNodeTag.new
    assert !tag.valid?, "Empty tag should be invalid"
    assert tag.errors[:old_node].any?
  end
  
  def test_uniqueness
    tag = OldNodeTag.new
    tag.node_id = node_tags(:t1).node_id
    tag.version = node_tags(:t1).version
    tag.k = node_tags(:t1).k
    tag.v = node_tags(:t1).v
    assert tag.new_record?
    assert !tag.valid?
    assert_raise(ActiveRecord::RecordInvalid) {tag.save!}
    assert tag.new_record?
  end
end
