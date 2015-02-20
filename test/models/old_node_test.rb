require "test_helper"

class OldNodeTest < ActiveSupport::TestCase
  api_fixtures

  def test_node_count
    assert_equal 23, OldNode.count
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
    node = nodes(nod)
    dbnode = Node.find(node.node_id)
    assert_equal dbnode.lat, node.latitude.to_f / OldNode::SCALE
    assert_equal dbnode.lon, node.longitude.to_f / OldNode::SCALE
    assert_equal dbnode.changeset_id, node.changeset_id
    assert_equal dbnode.version, node.version
    assert_equal dbnode.visible, node.visible
    assert_equal dbnode.timestamp, node.timestamp
    # assert_equal node.tile, QuadTile.tile_for_point(nodes(nod).lat, nodes(nod).lon)
    assert node.valid?
  end

  # This helpermethod will check to make sure that a node is outwith the world,
  # and has the same lat, lon and timesamp than what was put into the db by the
  # fixture
  def invalid_node_test(nod)
    node = nodes(nod)
    dbnode = Node.find(node.node_id)
    assert_equal dbnode.lat, node.latitude.to_f / OldNode::SCALE
    assert_equal dbnode.lon, node.longitude.to_f / OldNode::SCALE
    assert_equal dbnode.changeset_id, node.changeset_id
    assert_equal dbnode.version, node.version
    assert_equal dbnode.visible, node.visible
    assert_equal dbnode.timestamp, node.timestamp
    # assert_equal node.tile, QuadTile.tile_for_point(nodes(nod).lat, nodes(nod).lon)
    assert_equal false, node.valid?
  end

  def test_node_tags
    node = nodes(:node_with_versions_v1)
    tags = OldNode.find(node.id).old_tags.order(:k)
    assert_equal 0, tags.count

    node = nodes(:node_with_versions_v2)
    tags = OldNode.find(node.id).old_tags.order(:k)
    assert_equal 0, tags.count

    node = nodes(:node_with_versions_v3)
    tags = OldNode.find(node.id).old_tags.order(:k)
    assert_equal 3, tags.count
    assert_equal "testing", tags[0].k
    assert_equal "added in node version 3", tags[0].v
    assert_equal "testing three", tags[1].k
    assert_equal "added in node version 3", tags[1].v
    assert_equal "testing two", tags[2].k
    assert_equal "added in node version 3", tags[2].v

    node = nodes(:node_with_versions_v4)
    tags = OldNode.find(node.id).old_tags.order(:k)
    assert_equal 2, tags.count
    assert_equal "testing", tags[0].k
    assert_equal "added in node version 3", tags[0].v
    assert_equal "testing two", tags[1].k
    assert_equal "modified in node version 4", tags[1].v
  end

  def test_tags
    node = nodes(:node_with_versions_v1)
    tags = OldNode.find(node.id).tags
    assert_equal 0, tags.size

    node = nodes(:node_with_versions_v2)
    tags = OldNode.find(node.id).tags
    assert_equal 0, tags.size

    node = nodes(:node_with_versions_v3)
    tags = OldNode.find(node.id).tags
    assert_equal 3, tags.size
    assert_equal "added in node version 3", tags["testing"]
    assert_equal "added in node version 3", tags["testing two"]
    assert_equal "added in node version 3", tags["testing three"]

    node = nodes(:node_with_versions_v4)
    tags = OldNode.find(node.id).tags
    assert_equal 2, tags.size
    assert_equal "added in node version 3", tags["testing"]
    assert_equal "modified in node version 4", tags["testing two"]
  end
end
