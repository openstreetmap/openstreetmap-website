require File.dirname(__FILE__) + '/../test_helper'

class WayNodeTest < Test::Unit::TestCase
  api_fixtures
  
  def test_way_nodes_count
    assert_equal 4, WayNode.count
  end
  
end
