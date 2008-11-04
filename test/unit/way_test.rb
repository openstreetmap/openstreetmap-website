require File.dirname(__FILE__) + '/../test_helper'

class WayTest < Test::Unit::TestCase
  api_fixtures

  def test_bbox
    node = current_nodes(:used_node_1)
    [ :visible_way,
      :invisible_way,
      :used_way ].each do |way_symbol|
      way = current_ways(way_symbol)
      assert_equal node.bbox, way.bbox
    end
  end
  
end
