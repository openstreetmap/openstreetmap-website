require 'test_helper'

class NodeTagTest < ActiveSupport::TestCase
  api_fixtures
  
  def test_tag_count
    assert_equal 7, NodeTag.count
    node_tag_count(:visible_node, 1)
    node_tag_count(:invisible_node, 1)
    node_tag_count(:used_node_1, 1)
    node_tag_count(:used_node_2, 1)
    node_tag_count(:node_with_versions, 2)
  end
  
  def node_tag_count (node, count)
    nod = current_nodes(node)
    assert_equal count, nod.node_tags.count
  end
  
  def test_length_key_valid
    key = "k"
    (0..255).each do |i|
      tag = NodeTag.new
      tag.node_id = current_node_tags(:t1).node_id
      tag.k = key*i
      tag.v = "v"
      assert tag.valid?
    end
  end
  
  def test_length_value_valid
    val = "v"
    (0..255).each do |i|
      tag = NodeTag.new
      tag.node_id = current_node_tags(:t1).node_id
      tag.k = "k"
      tag.v = val*i
      assert tag.valid?
    end
  end
  
  def test_length_key_invalid
    ["k"*256].each do |i|
      tag = NodeTag.new
      tag.node_id = current_node_tags(:t1).node_id
      tag.k = i
      tag.v = "v"
      assert !tag.valid?, "Key should be too long"
      assert tag.errors[:k].any?
    end
  end
  
  def test_length_value_invalid
    ["k"*256].each do |i|
      tag = NodeTag.new
      tag.node_id = current_node_tags(:t1).node_id
      tag.k = "k"
      tag.v = i
      assert !tag.valid?, "Value should be too long"
      assert tag.errors[:v].any?
    end
  end
  
  def test_empty_node_tag_invalid
    tag = NodeTag.new
    assert !tag.valid?, "Empty tag should be invalid"
    assert tag.errors[:node].any?
  end
  
  def test_uniqueness
    tag = NodeTag.new
    tag.node_id = current_node_tags(:t1).node_id
    tag.k = current_node_tags(:t1).k
    tag.v = current_node_tags(:t1).v
    assert tag.new_record?
    assert !tag.valid?
    assert_raise(ActiveRecord::RecordInvalid) {tag.save!}
    assert tag.new_record?
  end
end
