require File.dirname(__FILE__) + '/../test_helper'

class OldWayTest < ActiveSupport::TestCase
  api_fixtures

  def test_db_count
    assert_equal 14, OldWay.count
  end

  def test_old_nodes
    way = ways(:way_with_multiple_nodes_v1)
    nodes = OldWay.find(way.id).old_nodes.order(:sequence_id)
    assert_equal 2, nodes.count
    assert_equal 2, nodes[0].node_id
    assert_equal 6, nodes[1].node_id

    way = ways(:way_with_multiple_nodes_v2)
    nodes = OldWay.find(way.id).old_nodes.order(:sequence_id)
    assert_equal 3, nodes.count
    assert_equal 4, nodes[0].node_id
    assert_equal 15, nodes[1].node_id
    assert_equal 6, nodes[2].node_id
  end

  def test_nds
    way = ways(:way_with_multiple_nodes_v1)
    nodes = OldWay.find(way.id).nds
    assert_equal 2, nodes.count
    assert_equal 2, nodes[0]
    assert_equal 6, nodes[1]

    way = ways(:way_with_multiple_nodes_v2)
    nodes = OldWay.find(way.id).nds
    assert_equal 3, nodes.count
    assert_equal 4, nodes[0]
    assert_equal 15, nodes[1]
    assert_equal 6, nodes[2]
  end

  def test_way_tags
    way = ways(:way_with_versions_v1)
    tags = OldWay.find(way.id).old_tags.order(:k)
    assert_equal 0, tags.count

    way = ways(:way_with_versions_v2)
    tags = OldWay.find(way.id).old_tags.order(:k)
    assert_equal 0, tags.count

    way = ways(:way_with_versions_v3)
    tags = OldWay.find(way.id).old_tags.order(:k)
    assert_equal 3, tags.count
    assert_equal "testing", tags[0].k 
    assert_equal "added in way version 3", tags[0].v
    assert_equal "testing three", tags[1].k
    assert_equal "added in way version 3", tags[1].v
    assert_equal "testing two", tags[2].k
    assert_equal "added in way version 3", tags[2].v

    way = ways(:way_with_versions_v4)
    tags = OldWay.find(way.id).old_tags.order(:k)
    assert_equal 2, tags.count
    assert_equal "testing", tags[0].k 
    assert_equal "added in way version 3", tags[0].v
    assert_equal "testing two", tags[1].k
    assert_equal "modified in way version 4", tags[1].v
  end

  def test_tags
    way = ways(:way_with_versions_v1)
    tags = OldWay.find(way.id).tags
    assert_equal 0, tags.size

    way = ways(:way_with_versions_v2)
    tags = OldWay.find(way.id).tags
    assert_equal 0, tags.size

    way = ways(:way_with_versions_v3)
    tags = OldWay.find(way.id).tags
    assert_equal 3, tags.size
    assert_equal "added in way version 3", tags["testing"]
    assert_equal "added in way version 3", tags["testing two"]
    assert_equal "added in way version 3", tags["testing three"]

    way = ways(:way_with_versions_v4)
    tags = OldWay.find(way.id).tags
    assert_equal 2, tags.size
    assert_equal "added in way version 3", tags["testing"]
    assert_equal "modified in way version 4", tags["testing two"]
  end
end
