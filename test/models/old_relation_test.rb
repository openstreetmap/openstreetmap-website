require 'test_helper'

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

  def test_relation_members
    relation = relations(:relation_with_versions_v1)
    members = OldRelation.find(relation.id).relation_members
    assert_equal 1, members.count
    assert_equal "some node", members[0].member_role
    assert_equal "Node", members[0].member_type
    assert_equal 15, members[0].member_id

    relation = relations(:relation_with_versions_v2)
    members = OldRelation.find(relation.id).relation_members
    assert_equal 1, members.count
    assert_equal "some changed node", members[0].member_role
    assert_equal "Node", members[0].member_type
    assert_equal 15, members[0].member_id

    relation = relations(:relation_with_versions_v3)
    members = OldRelation.find(relation.id).relation_members
    assert_equal 2, members.count
    assert_equal "some changed node", members[0].member_role
    assert_equal "Node", members[0].member_type
    assert_equal 15, members[0].member_id
    assert_equal "some relation", members[1].member_role
    assert_equal "Relation", members[1].member_type
    assert_equal 7, members[1].member_id

    relation = relations(:relation_with_versions_v4)
    members = OldRelation.find(relation.id).relation_members
    assert_equal 3, members.count
    assert_equal "some node", members[0].member_role
    assert_equal "Node", members[0].member_type
    assert_equal 15, members[0].member_id
    assert_equal "some way", members[1].member_role
    assert_equal "Way", members[1].member_type
    assert_equal 4, members[1].member_id
    assert_equal "some relation", members[2].member_role
    assert_equal "Relation", members[2].member_type
    assert_equal 7, members[2].member_id
  end

  def test_relations
    relation = relations(:relation_with_versions_v1)
    members = OldRelation.find(relation.id).members
    assert_equal 1, members.count
    assert_equal ["Node", 15, "some node"], members[0]

    relation = relations(:relation_with_versions_v2)
    members = OldRelation.find(relation.id).members
    assert_equal 1, members.count
    assert_equal ["Node", 15, "some changed node"], members[0]

    relation = relations(:relation_with_versions_v3)
    members = OldRelation.find(relation.id).members
    assert_equal 2, members.count
    assert_equal ["Node", 15, "some changed node"], members[0]
    assert_equal ["Relation", 7, "some relation"], members[1]

    relation = relations(:relation_with_versions_v4)
    members = OldRelation.find(relation.id).members
    assert_equal 3, members.count
    assert_equal ["Node", 15, "some node"], members[0]
    assert_equal ["Way", 4, "some way"], members[1]
    assert_equal ["Relation", 7, "some relation"], members[2]
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
