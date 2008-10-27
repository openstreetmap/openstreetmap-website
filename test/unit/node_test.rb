require File.dirname(__FILE__) + '/../test_helper'

class NodeTest < Test::Unit::TestCase
  fixtures :changesets, :current_nodes, :users, :current_node_tags, :nodes, :node_tags
  set_fixture_class :current_nodes => Node
  set_fixture_class :nodes => OldNode
  set_fixture_class :node_tags => OldNodeTag
  set_fixture_class :current_node_tags => NodeTag
    
  def test_node_too_far_north
	  invalid_node_test(:node_too_far_north)
  end
  
  def test_node_north_limit
    valid_node_test(:node_north_limit)
  end
  
  def test_node_too_far_south
    invalid_node_test(:node_too_far_south)
  end
  
  def test_node_south_limit
    valid_node_test(:node_south_limit)
  end
  
  def test_node_too_far_west
    invalid_node_test(:node_too_far_west)
  end
  
  def test_node_west_limit
    valid_node_test(:node_west_limit)
  end
  
  def test_node_too_far_east
    invalid_node_test(:node_too_far_east)
  end
  
  def test_node_east_limit
    valid_node_test(:node_east_limit)
  end
  
  def test_totally_wrong
    invalid_node_test(:node_totally_wrong)
  end
  
  # This helper method will check to make sure that a node is within the world, and
  # has the the same lat, lon and timestamp than what was put into the db by 
  # the fixture
  def valid_node_test(nod)
    node = current_nodes(nod)
    dbnode = Node.find(node.id)
    assert_equal dbnode.lat, node.latitude.to_f/SCALE
    assert_equal dbnode.lon, node.longitude.to_f/SCALE
    assert_equal dbnode.changeset_id, node.changeset_id
    assert_equal dbnode.timestamp, node.timestamp
    assert_equal dbnode.version, node.version
    assert_equal dbnode.visible, node.visible
    #assert_equal node.tile, QuadTile.tile_for_point(node.lat, node.lon)
    assert_valid node
  end
  
  # This helper method will check to make sure that a node is outwith the world, 
  # and has the same lat, lon and timesamp than what was put into the db by the
  # fixture
  def invalid_node_test(nod)
    node = current_nodes(nod)
    dbnode = Node.find(node.id)
    assert_equal dbnode.lat, node.latitude.to_f/SCALE
    assert_equal dbnode.lon, node.longitude.to_f/SCALE
    assert_equal dbnode.changeset_id, node.changeset_id
    assert_equal dbnode.timestamp, node.timestamp
    assert_equal dbnode.version, node.version
    assert_equal dbnode.visible, node.visible
    #assert_equal node.tile, QuadTile.tile_for_point(node.lat, node.lon)
    assert_equal false, dbnode.valid?
  end
  
  # Check that you can create a node and store it
  def test_create
    node_template = Node.new(:latitude => 12.3456,
                             :longitude => 65.4321,
                             :changeset_id => changesets(:normal_user_first_change),
                             :visible => 1, 
                             :version => 1)
    assert node_template.save_with_history!

    node = Node.find(node_template.id)
    assert_not_nil node
    assert_equal node_template.latitude, node.latitude
    assert_equal node_template.longitude, node.longitude
    assert_equal node_template.changeset_id, node.changeset_id
    assert_equal node_template.visible, node.visible
    assert_equal node_template.timestamp.to_i, node.timestamp.to_i

    assert_equal OldNode.find(:all, :conditions => [ "id = ?", node_template.id ]).length, 1
    old_node = OldNode.find(:first, :conditions => [ "id = ?", node_template.id ])
    assert_not_nil old_node
    assert_equal node_template.latitude, old_node.latitude
    assert_equal node_template.longitude, old_node.longitude
    assert_equal node_template.changeset_id, old_node.changeset_id
    assert_equal node_template.visible, old_node.visible
    assert_equal node_template.tags, old_node.tags
    assert_equal node_template.timestamp.to_i, old_node.timestamp.to_i
  end

  def test_update
    node_template = Node.find(current_nodes(:visible_node).id)
    assert_not_nil node_template

    assert_equal OldNode.find(:all, :conditions => [ "id = ?", node_template.id ]).length, 1
    old_node_template = OldNode.find(:first, :conditions => [ "id = ?", node_template.id ])
    assert_not_nil old_node_template

    node_template.latitude = 12.3456
    node_template.longitude = 65.4321
    #node_template.tags = "updated=yes"
    assert node_template.save_with_history!

    node = Node.find(node_template.id)
    assert_not_nil node
    assert_equal node_template.latitude, node.latitude
    assert_equal node_template.longitude, node.longitude
    assert_equal node_template.changeset_id, node.changeset_id
    assert_equal node_template.visible, node.visible
    #assert_equal node_template.tags, node.tags
    assert_equal node_template.timestamp.to_i, node.timestamp.to_i

    assert_equal OldNode.find(:all, :conditions => [ "id = ?", node_template.id ]).length, 2
    assert_equal OldNode.find(:all, :conditions => [ "id = ? and timestamp = ?", node_template.id, node_template.timestamp ]).length, 1
    old_node = OldNode.find(:first, :conditions => [ "id = ? and timestamp = ?", node_template.id, node_template.timestamp ])
    assert_not_nil old_node
    assert_equal node_template.latitude, old_node.latitude
    assert_equal node_template.longitude, old_node.longitude
    assert_equal node_template.changeset_id, old_node.changeset_id
    assert_equal node_template.visible, old_node.visible
    #assert_equal node_template.tags, old_node.tags
    assert_equal node_template.timestamp.to_i, old_node.timestamp.to_i
  end

  def test_delete
    node_template = Node.find(current_nodes(:visible_node))
    assert_not_nil node_template

    assert_equal OldNode.find(:all, :conditions => [ "id = ?", node_template.id ]).length, 1
    old_node_template = OldNode.find(:first, :conditions => [ "id = ?", node_template.id ])
    assert_not_nil old_node_template

    node_template.visible = 0
    assert node_template.save_with_history!

    node = Node.find(node_template.id)
    assert_not_nil node
    assert_equal node_template.latitude, node.latitude
    assert_equal node_template.longitude, node.longitude
    assert_equal node_template.changeset_id, node.changeset_id
    assert_equal node_template.visible, node.visible
    #assert_equal node_template.tags, node.tags
    assert_equal node_template.timestamp.to_i, node.timestamp.to_i

    assert_equal OldNode.find(:all, :conditions => [ "id = ?", node_template.id ]).length, 2
    assert_equal OldNode.find(:all, :conditions => [ "id = ? and timestamp = ?", node_template.id, node_template.timestamp ]).length, 1
    old_node = OldNode.find(:first, :conditions => [ "id = ? and timestamp = ?", node_template.id, node_template.timestamp ])
    assert_not_nil old_node
    assert_equal node_template.latitude, old_node.latitude
    assert_equal node_template.longitude, old_node.longitude
    assert_equal node_template.changeset_id, old_node.changeset_id
    assert_equal node_template.visible, old_node.visible
    #assert_equal node_template.tags, old_node.tags
    assert_equal node_template.timestamp.to_i, old_node.timestamp.to_i
  end
end
