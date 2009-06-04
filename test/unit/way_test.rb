require File.dirname(__FILE__) + '/../test_helper'

class WayTest < ActiveSupport::TestCase
  api_fixtures

  # Check that we have the correct number of currnet ways in the db
  # This will need to updated whenever the current_ways.yml is updated
  def test_db_count
    assert_equal 4, Way.count
  end
  
  def test_bbox
    node = current_nodes(:used_node_1)
    [ :visible_way,
      :invisible_way,
      :used_way ].each do |way_symbol|
      way = current_ways(way_symbol)
      assert_equal node.bbox, way.bbox
    end
  end
  
  # Check that the preconditions fail when you are over the defined limit of 
  # the maximum number of nodes in each way.
  def test_max_nodes_per_way_limit
    # Take one of the current ways and add nodes to it until we are near the limit
    way = Way.find(current_ways(:visible_way).id)
    assert way.valid?
    # it already has 1 node
    1.upto((APP_CONFIG['max_number_of_way_nodes'])/2) {
      way.add_nd_num(current_nodes(:used_node_1).id)
      way.add_nd_num(current_nodes(:used_node_2).id)
    }
    way.save
    #print way.nds.size
    assert way.valid?
    way.add_nd_num(current_nodes(:visible_node).id)
    assert way.valid?
  end
end
