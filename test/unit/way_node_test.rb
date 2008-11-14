require File.dirname(__FILE__) + '/../test_helper'

class WayNodeTest < Test::Unit::TestCase
  fixtures :way_nodes
  set_fixture_class :way_nodes=>OldWayNode
  set_fixture_class :current_way_nodes=>WayNode
  
  def test_way_nodes_count
    assert_equal 4, WayNode.count
  end
  
end
