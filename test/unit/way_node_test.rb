require File.dirname(__FILE__) + '/../test_helper'

class WayNodeTest < ActiveSupport::TestCase
  api_fixtures

  def test_way_nodes_count
    assert_equal 9, WayNode.count
  end
end
