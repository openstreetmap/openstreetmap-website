require File.dirname(__FILE__) + '/../test_helper'

class OldRelationTest < ActiveSupport::TestCase
  api_fixtures

  def test_db_count
    assert_equal 14, OldRelation.count
  end

  def test_relation_tags
    relation = relations(:relation_with_versions_v1)
    tags = OldRelation.find(relation.id).old_tags.order(:k)
    assert_equal 0, tags.count

    relation = relations(:relation_with_versions_v2)
    tags = OldRelation.find(relation.id).old_tags.order(:k)
    assert_equal 0, tags.count

    relation = relations(:relation_with_versions_v3)
    tags = OldRelation.find(relation.id).old_tags.order(:k)
    assert_equal 3, tags.count
    assert_equal "testing", tags[0].k 
    assert_equal "added in relation version 3", tags[0].v
    assert_equal "testing three", tags[1].k
    assert_equal "added in relation version 3", tags[1].v
    assert_equal "testing two", tags[2].k
    assert_equal "added in relation version 3", tags[2].v

    relation = relations(:relation_with_versions_v4)
    tags = OldRelation.find(relation.id).old_tags.order(:k)
    assert_equal 2, tags.count
    assert_equal "testing", tags[0].k 
    assert_equal "added in relation version 3", tags[0].v
    assert_equal "testing two", tags[1].k
    assert_equal "modified in relation version 4", tags[1].v
  end

  def test_tags
    relation = relations(:relation_with_versions_v1)
    tags = OldRelation.find(relation.id).tags
    assert_equal 0, tags.size

    relation = relations(:relation_with_versions_v2)
    tags = OldRelation.find(relation.id).tags
    assert_equal 0, tags.size

    relation = relations(:relation_with_versions_v3)
    tags = OldRelation.find(relation.id).tags
    assert_equal 3, tags.size
    assert_equal "added in relation version 3", tags["testing"]
    assert_equal "added in relation version 3", tags["testing two"]
    assert_equal "added in relation version 3", tags["testing three"]

    relation = relations(:relation_with_versions_v4)
    tags = OldRelation.find(relation.id).tags
    assert_equal 2, tags.size
    assert_equal "added in relation version 3", tags["testing"]
    assert_equal "modified in relation version 4", tags["testing two"]
  end
end
