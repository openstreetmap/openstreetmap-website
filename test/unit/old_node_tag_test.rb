require File.dirname(__FILE__) + '/../test_helper'

class OldNodeTest < Test::Unit::TestCase
  set_fixture_class :nodes => OldNode
  set_fixture_class :node_tags => OldNodeTag
  fixtures  :users, :nodes, :node_tags
  
  def test_old_node_tag_count
    assert_equal 8, OldNodeTag.count, "Unexpected number of fixtures loaded."
  end
  
  def test_length_key_valid
    key = "k"
    (0..255).each do |i|
      tag = OldNodeTag.new
      tag.id = node_tags(:t1).id
      tag.version = node_tags(:t1).version
      tag.k = key*i
      tag.v = "v"
      assert_valid tag
    end
  end
  
  def test_length_value_valid
    val = "v"
    (0..255).each do |i|
      tag = OldNodeTag.new
      tag.id = node_tags(:t1).id
      tag.version = node_tags(:t1).version
      tag.k = "k"
      tag.v = val*i
      assert_valid tag
    end
  end
  
  def test_length_key_invalid
    ["k"*256].each do |i|
      tag = OldNodeTag.new
      tag.id = node_tags(:t1).id
      tag.version = node_tags(:t1).version
      tag.k = i
      tag.v = "v", "Key should be too long"
      assert !tag.valid?
      assert tag.errors.invalid?(:k)
    end
  end
  
  def test_length_value_invalid
    ["k"*256].each do |i|
      tag = OldNodeTag.new
      tag.id = node_tags(:t1).id
      tag.version = node_tags(:t1).version
      tag.k = "k"
      tag.v = i
      assert !tag.valid?, "Value should be too long"
      assert tag.errors.invalid?(:v)
    end
  end
  
  def test_empty_old_node_tag_invalid
    tag = OldNodeTag.new
    assert !tag.valid?, "Empty tag should be invalid"
    assert tag.errors.invalid?(:id)
    assert tag.errors.invalid?(:version)
  end
end
