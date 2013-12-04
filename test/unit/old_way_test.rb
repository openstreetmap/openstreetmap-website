require File.dirname(__FILE__) + '/../test_helper'

class OldWayTest < ActiveSupport::TestCase
  api_fixtures

  def test_db_count
    assert_equal 12, OldWay.count
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
