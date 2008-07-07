require File.dirname(__FILE__) + '/../test_helper'

class NodeTest < Test::Unit::TestCase
  fixtures :current_nodes, :users, :current_node_tags,:nodes,  :node_tags
  set_fixture_class :current_nodes => :Node
  set_fixture_class :nodes => :OldNode
  set_fixture_class :node_tags => :OldNodeTag
  set_fixture_class :currenr_node_tags => :NodeTag
    
  def test_node_too_far_north
	  node = current_nodes(:node_too_far_north)
    assert_equal node.lat, current_nodes(:node_too_far_north).latitude/SCALE
    assert_equal node.lon, current_nodes(:node_too_far_north).longitude/SCALE
    assert_equal false, node.valid?
  end
  
  def test_node_too_far_south
    node = current_nodes(:node_too_far_south)
    assert_equal node.lat, current_nodes(:node_too_far_south).latitude/SCALE
    assert_equal node.lon, current_nodes(:node_too_far_south).longitude/SCALE
    assert_equal false, node.valid?
  end
  
  def test_node_too_far_west
    node = current_nodes(:node_too_far_west)
    assert_equal node.lat, current_nodes(:node_too_far_west).latitude/SCALE
    assert_equal node.lon, current_nodes(:node_too_far_west).longitude/SCALE
    assert_equal false, node.valid?
  end
  
  def test_node_too_far_east
    node = current_nodes(:node_too_far_east)
    assert_equal node.lat, current_nodes(:node_too_far_east).latitude/SCALE
    assert_equal node.lon, current_nodes(:node_too_far_east).longitude/SCALE
    assert_equal false, node.valid?
  end
  
  def test_totally_wrong
    node = current_nodes(:node_totally_wrong)
    #assert_equal node.lat, current_nodes(:node_totally_wrong).latitude/SCALE
    #assert_equal node.lon, current_nodes(:node_totally_wrong).longitude/SCALE
    assert_equal false, node.valid?
  end
  
  def test_create
    node_template = Node.new(:latitude => 12.3456,
                             :longitude => 65.4321,
                             :user_id => users(:normal_user),
                             :visible => 1, 
                             :version => 1)
    assert node_template.save_with_history!

    node = Node.find(node_template.id)
    assert_not_nil node
    assert_equal node_template.latitude, node.latitude
    assert_equal node_template.longitude, node.longitude
    assert_equal node_template.user_id, node.user_id
    assert_equal node_template.visible, node.visible
    assert_equal node_template.timestamp.to_i, node.timestamp.to_i

    assert_equal OldNode.find(:all, :conditions => [ "id = ?", node_template.id ]).length, 1
    old_node = OldNode.find(:first, :conditions => [ "id = ?", node_template.id ])
    assert_not_nil old_node
    assert_equal node_template.latitude, old_node.latitude
    assert_equal node_template.longitude, old_node.longitude
    assert_equal node_template.user_id, old_node.user_id
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
    assert_equal node_template.user_id, node.user_id
    assert_equal node_template.visible, node.visible
    #assert_equal node_template.tags, node.tags
    assert_equal node_template.timestamp.to_i, node.timestamp.to_i

    assert_equal OldNode.find(:all, :conditions => [ "id = ?", node_template.id ]).length, 2
    assert_equal OldNode.find(:all, :conditions => [ "id = ? and timestamp = ?", node_template.id, node_template.timestamp ]).length, 1
    old_node = OldNode.find(:first, :conditions => [ "id = ? and timestamp = ?", node_template.id, node_template.timestamp ])
    assert_not_nil old_node
    assert_equal node_template.latitude, old_node.latitude
    assert_equal node_template.longitude, old_node.longitude
    assert_equal node_template.user_id, old_node.user_id
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
    assert_equal node_template.user_id, node.user_id
    assert_equal node_template.visible, node.visible
    #assert_equal node_template.tags, node.tags
    assert_equal node_template.timestamp.to_i, node.timestamp.to_i

    assert_equal OldNode.find(:all, :conditions => [ "id = ?", node_template.id ]).length, 2
    assert_equal OldNode.find(:all, :conditions => [ "id = ? and timestamp = ?", node_template.id, node_template.timestamp ]).length, 1
    old_node = OldNode.find(:first, :conditions => [ "id = ? and timestamp = ?", node_template.id, node_template.timestamp ])
    assert_not_nil old_node
    assert_equal node_template.latitude, old_node.latitude
    assert_equal node_template.longitude, old_node.longitude
    assert_equal node_template.user_id, old_node.user_id
    assert_equal node_template.visible, old_node.visible
    #assert_equal node_template.tags, old_node.tags
    assert_equal node_template.timestamp.to_i, old_node.timestamp.to_i
  end
end
