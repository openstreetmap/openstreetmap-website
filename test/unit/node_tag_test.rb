require File.dirname(__FILE__) + '/../test_helper'

class NodeTagTest < Test::Unit::TestCase
  fixtures :current_node_tags
  set_fixture_class :current_node_tags => NodeTag
  
  def test_node_tag_count
    assert_equal 6, NodeTag.count
  end
  
end
