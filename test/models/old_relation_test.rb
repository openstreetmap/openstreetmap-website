require "test_helper"

class OldRelationTest < ActiveSupport::TestCase
  api_fixtures

  def test_relation_tags
    old_relation_v1 = create(:old_relation, :version => 1)
    old_relation_v2 = create(:old_relation, :current_relation => old_relation_v1.current_relation, :version => 2)
    old_relation_v3 = create(:old_relation, :current_relation => old_relation_v1.current_relation, :version => 3)
    old_relation_v4 = create(:old_relation, :current_relation => old_relation_v1.current_relation, :version => 4)
    taglist_v3 = create_list(:old_relation_tag, 3, :old_relation => old_relation_v3)
    taglist_v4 = create_list(:old_relation_tag, 2, :old_relation => old_relation_v4)

    tags = OldRelation.find(old_relation_v1.id).old_tags.order(:k)
    assert_equal 0, tags.count

    tags = OldRelation.find(old_relation_v2.id).old_tags.order(:k)
    assert_equal 0, tags.count

    tags = OldRelation.find(old_relation_v3.id).old_tags.order(:k)
    assert_equal taglist_v3.count, tags.count
    taglist_v3.sort_by!(&:k).each_index do |i|
      assert_equal taglist_v3[i].k, tags[i].k
      assert_equal taglist_v3[i].v, tags[i].v
    end

    tags = OldRelation.find(old_relation_v4.id).old_tags.order(:k)
    assert_equal taglist_v4.count, tags.count
    taglist_v4.sort_by!(&:k).each_index do |i|
      assert_equal taglist_v4[i].k, tags[i].k
      assert_equal taglist_v4[i].v, tags[i].v
    end
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
    old_relation_v1 = create(:old_relation, :version => 1)
    old_relation_v2 = create(:old_relation, :current_relation => old_relation_v1.current_relation, :version => 2)
    old_relation_v3 = create(:old_relation, :current_relation => old_relation_v1.current_relation, :version => 3)
    old_relation_v4 = create(:old_relation, :current_relation => old_relation_v1.current_relation, :version => 4)
    taglist_v3 = create_list(:old_relation_tag, 3, :old_relation => old_relation_v3)
    taglist_v4 = create_list(:old_relation_tag, 2, :old_relation => old_relation_v4)

    tags = OldRelation.find(old_relation_v1.id).tags
    assert_equal 0, tags.size

    tags = OldRelation.find(old_relation_v2.id).tags
    assert_equal 0, tags.size

    tags = OldRelation.find(old_relation_v3.id).tags
    assert_equal taglist_v3.count, tags.count
    taglist_v3.each do |tag|
      assert_equal tag.v, tags[tag.k]
    end

    tags = OldRelation.find(old_relation_v4.id).tags
    assert_equal taglist_v4.count, tags.count
    taglist_v4.each do |tag|
      assert_equal tag.v, tags[tag.k]
    end
  end
end
