require File.dirname(__FILE__) + '/../test_helper'

class CurrentNodeTagTest < Test::Unit::TestCase
  fixtures :current_node_tags, :current_nodes
  set_fixture_class :current_nodes => Node
  set_fixture_class :current_node_tags => NodeTag
  
  def test_tag_count
    assert_equal 6, NodeTag.count
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
  
end
