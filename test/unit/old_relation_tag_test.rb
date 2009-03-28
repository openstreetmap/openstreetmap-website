require File.dirname(__FILE__) + '/../test_helper'

class OldRelationTagTest < Test::Unit::TestCase
  api_fixtures
  
  def test_tag_count
    assert_equal 3, OldRelationTag.count
  end
  
  def test_length_key_valid
    key = "k"
    (0..255).each do |i|
      tag = OldRelationTag.new
      tag.id = relation_tags(:t1).id
      tag.version = 1
      tag.k = key*i
      tag.v = "v"
      assert_valid tag
    end
  end
  
  def test_length_value_valid
    val = "v"
    (0..255).each do |i|
      tag = OldRelationTag.new
      tag.id = relation_tags(:t1).id
      tag.version = 1
      tag.k = "k"
      tag.v = val*i
      assert_valid tag
    end
  end
  
  def test_length_key_invalid
    ["k"*256].each do |i|
      tag = OldRelationTag.new
      tag.id = relation_tags(:t1).id
      tag.version = 1
      tag.k = i
      tag.v = "v"
      assert !tag.valid?, "Key should be too long"
      assert tag.errors.invalid?(:k)
    end
  end
  
  def test_length_value_invalid
    ["k"*256].each do |i|
      tag = OldRelationTag.new
      tag.id = relation_tags(:t1).id
      tag.version = 1
      tag.k = "k"
      tag.v = i
      assert !tag.valid?, "Value should be too long"
      assert tag.errors.invalid?(:v)
    end
  end
  
  def test_empty_node_tag_invalid
    tag = OldRelationTag.new
    assert !tag.valid?, "Empty tag should be invalid"
    assert tag.errors.invalid?(:id)
  end
  
  def test_uniqueness
    tag = OldRelationTag.new
    tag.id = relation_tags(:t1).id
    tag.version = relation_tags(:t1).version
    tag.k = relation_tags(:t1).k
    tag.v = relation_tags(:t1).v
    assert tag.new_record?
    assert !tag.valid?
    assert_raise(ActiveRecord::RecordInvalid) {tag.save!}
    assert tag.new_record?
  end
end
