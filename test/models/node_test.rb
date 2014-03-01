require 'test_helper'

class NodeTest < ActiveSupport::TestCase
  api_fixtures
  
  def test_node_count
    assert_equal 18, Node.count
  end

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
    assert node.valid?
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
    node_template = Node.new(
      :latitude => 12.3456,
      :longitude => 65.4321,
      :changeset_id => changesets(:normal_user_first_change).id,
      :visible => 1, 
      :version => 1
    )
    assert node_template.create_with_history(users(:normal_user))

    node = Node.find(node_template.id)
    assert_not_nil node
    assert_equal node_template.latitude, node.latitude
    assert_equal node_template.longitude, node.longitude
    assert_equal node_template.changeset_id, node.changeset_id
    assert_equal node_template.visible, node.visible
    assert_equal node_template.timestamp.to_i, node.timestamp.to_i

    assert_equal OldNode.where(:node_id => node_template.id).count, 1
    old_node = OldNode.where(:node_id => node_template.id).first
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

    assert_equal OldNode.where(:node_id => node_template.id).count, 1
    node = Node.find(node_template.id)
    assert_not_nil node

    node_template.latitude = 12.3456
    node_template.longitude = 65.4321
    #node_template.tags = "updated=yes"
    assert node.update_from(node_template, users(:normal_user))

    node = Node.find(node_template.id)
    assert_not_nil node
    assert_equal node_template.latitude, node.latitude
    assert_equal node_template.longitude, node.longitude
    assert_equal node_template.changeset_id, node.changeset_id
    assert_equal node_template.visible, node.visible
    #assert_equal node_template.tags, node.tags

    assert_equal OldNode.where(:node_id => node_template.id).count, 2
    old_node = OldNode.where(:node_id => node_template.id, :version => 2).first
    assert_not_nil old_node
    assert_equal node_template.latitude, old_node.latitude
    assert_equal node_template.longitude, old_node.longitude
    assert_equal node_template.changeset_id, old_node.changeset_id
    assert_equal node_template.visible, old_node.visible
    #assert_equal node_template.tags, old_node.tags
  end

  def test_delete
    node_template = Node.find(current_nodes(:visible_node))
    assert_not_nil node_template

    assert_equal OldNode.where(:node_id => node_template.id).count, 1
    node = Node.find(node_template.id)
    assert_not_nil node

    assert node.delete_with_history!(node_template, users(:normal_user))

    node = Node.find(node_template.id)
    assert_not_nil node
    assert_equal node_template.latitude, node.latitude
    assert_equal node_template.longitude, node.longitude
    assert_equal node_template.changeset_id, node.changeset_id
    assert_equal false, node.visible
    #assert_equal node_template.tags, node.tags

    assert_equal OldNode.where(:node_id => node_template.id).count, 2
    old_node = OldNode.where(:node_id => node_template.id, :version => 2).first
    assert_not_nil old_node
    assert_equal node_template.latitude, old_node.latitude
    assert_equal node_template.longitude, old_node.longitude
    assert_equal node_template.changeset_id, old_node.changeset_id
    assert_equal false, old_node.visible
    #assert_equal node_template.tags, old_node.tags
  end
  
  def test_from_xml_no_id
    lat = 56.7
    lon = -2.3
    changeset = 2
    version = 1
    noid = "<osm><node lat='#{lat}' lon='#{lon}' changeset='#{changeset}' version='#{version}' /></osm>"
    # First try a create which doesn't need the id
    assert_nothing_raised(OSM::APIBadXMLError) {
      Node.from_xml(noid, true)
    }
    # Now try an update with no id, and make sure that it gives the appropriate exception
    message = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(noid, false)
    }
    assert_match /ID is required when updating./, message.message
  end
  
  def test_from_xml_no_lat
    nolat = "<osm><node id='1' lon='23.3' changeset='2' version='23' /></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(nolat, true)
    }
    assert_match /lat missing/, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(nolat, false)
    }
    assert_match /lat missing/, message_update.message
  end
  
  def test_from_xml_no_lon
    nolon = "<osm><node id='1' lat='23.1' changeset='2' version='23' /></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(nolon, true)
    }
    assert_match /lon missing/, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(nolon, false)
    }
    assert_match /lon missing/, message_update.message
  end

  def test_from_xml_no_changeset_id
    nocs = "<osm><node id='123' lon='23.23' lat='23.1' version='23' /></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(nocs, true)
    }
    assert_match /Changeset id is missing/, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(nocs, false)
    }
    assert_match /Changeset id is missing/, message_update.message
  end
  
  def test_from_xml_no_version
    no_version = "<osm><node id='123' lat='23' lon='23' changeset='23' /></osm>"
    assert_nothing_raised(OSM::APIBadXMLError) {
      Node.from_xml(no_version, true)
    }
    message_update = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(no_version, false)
    }
    assert_match /Version is required when updating/, message_update.message
  end
  
  def test_from_xml_double_lat
    nocs = "<osm><node id='123' lon='23.23' lat='23.1' lat='12' changeset='23' version='23' /></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(nocs, true)
    } 
    assert_match /Fatal error: Attribute lat redefined at/, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(nocs, false)
    }
    assert_match /Fatal error: Attribute lat redefined at/, message_update.message
  end
  
  def test_from_xml_id_zero
    id_list = ["", "0", "00", "0.0", "a"]
    id_list.each do |id|
      zero_id = "<osm><node id='#{id}' lat='12.3' lon='12.3' changeset='33' version='23' /></osm>"
      assert_nothing_raised(OSM::APIBadUserInput) {
        Node.from_xml(zero_id, true)
      }
      message_update = assert_raise(OSM::APIBadUserInput) {
        Node.from_xml(zero_id, false)
      }
      assert_match /ID of node cannot be zero when updating/, message_update.message
    end
  end
  
  def test_from_xml_no_text
    no_text = ""
    message_create = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(no_text, true)
    }
    assert_match /Must specify a string with one or more characters/, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(no_text, false)
    }
    assert_match /Must specify a string with one or more characters/, message_update.message
  end
  
  def test_from_xml_no_node
    no_node = "<osm></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(no_node, true)
    }
    assert_match /XML doesn't contain an osm\/node element/, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(no_node, false)
    }
    assert_match /XML doesn't contain an osm\/node element/, message_update.message
  end
  
  def test_from_xml_no_k_v
    nokv = "<osm><node id='23' lat='12.3' lon='23.4' changeset='12' version='23'><tag /></node></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(nokv, true)
    }
    assert_match /tag is missing key/, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(nokv, false)
    }
    assert_match /tag is missing key/, message_update.message
  end
  
  def test_from_xml_no_v
    no_v = "<osm><node id='23' lat='23.43' lon='23.32' changeset='23' version='32'><tag k='key' /></node></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(no_v, true)
    }
    assert_match /tag is missing value/, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) {
      Node.from_xml(no_v, false)
    }
    assert_match /tag is missing value/, message_update.message
  end
  
  def test_from_xml_duplicate_k
    dupk = "<osm><node id='23' lat='23.2' lon='23' changeset='34' version='23'><tag k='dup' v='test' /><tag k='dup' v='tester' /></node></osm>"
    message_create = assert_raise(OSM::APIDuplicateTagsError) {
      Node.from_xml(dupk, true)
    }
    assert_equal "Element node/ has duplicate tags with key dup", message_create.message
    message_update = assert_raise(OSM::APIDuplicateTagsError) {
      Node.from_xml(dupk, false)
    }
    assert_equal "Element node/23 has duplicate tags with key dup", message_update.message
  end

  def test_node_tags
    node = current_nodes(:node_with_versions)
    tags = Node.find(node.id).node_tags.order(:k)
    assert_equal 2, tags.count
    assert_equal "testing", tags[0].k 
    assert_equal "added in node version 3", tags[0].v
    assert_equal "testing two", tags[1].k
    assert_equal "modified in node version 4", tags[1].v
  end

  def test_tags
    node = current_nodes(:node_with_versions)
    tags = Node.find(node.id).tags
    assert_equal 2, tags.size
    assert_equal "added in node version 3", tags["testing"]
    assert_equal "modified in node version 4", tags["testing two"]
  end
end
