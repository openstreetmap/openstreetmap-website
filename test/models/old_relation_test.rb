require "test_helper"

class OldRelationTest < ActiveSupport::TestCase
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
    old_relation_v1 = create(:old_relation)
    old_relation_v2 = create(:old_relation, :current_relation => old_relation_v1.current_relation, :version => 2)
    old_relation_v3 = create(:old_relation, :current_relation => old_relation_v1.current_relation, :version => 3)
    old_relation_v4 = create(:old_relation, :current_relation => old_relation_v1.current_relation, :version => 4)
    member_node = create(:node)
    member_way = create(:way)
    member_relation = create(:relation)
    create(:old_relation_member, :old_relation => old_relation_v1, :member => member_node, :member_role => "some node")
    create(:old_relation_member, :old_relation => old_relation_v2, :member => member_node, :member_role => "some changed node")
    create(:old_relation_member, :old_relation => old_relation_v3, :member => member_node, :member_role => "some changed node")
    create(:old_relation_member, :old_relation => old_relation_v3, :member => member_relation, :member_role => "some relation")
    create(:old_relation_member, :old_relation => old_relation_v4, :member => member_node, :member_role => "some node")
    create(:old_relation_member, :old_relation => old_relation_v4, :member => member_way, :member_role => "some way")
    create(:old_relation_member, :old_relation => old_relation_v4, :member => member_relation, :member_role => "some relation")

    members = OldRelation.find(old_relation_v1.id).relation_members
    assert_equal 1, members.count
    assert_equal "some node", members[0].member_role
    assert_equal "Node", members[0].member_type
    assert_equal member_node.id, members[0].member_id

    members = OldRelation.find(old_relation_v2.id).relation_members
    assert_equal 1, members.count
    assert_equal "some changed node", members[0].member_role
    assert_equal "Node", members[0].member_type
    assert_equal member_node.id, members[0].member_id

    members = OldRelation.find(old_relation_v3.id).relation_members
    assert_equal 2, members.count
    assert_equal "some changed node", members[0].member_role
    assert_equal "Node", members[0].member_type
    assert_equal member_node.id, members[0].member_id
    assert_equal "some relation", members[1].member_role
    assert_equal "Relation", members[1].member_type
    assert_equal member_relation.id, members[1].member_id

    members = OldRelation.find(old_relation_v4.id).relation_members
    assert_equal 3, members.count
    assert_equal "some node", members[0].member_role
    assert_equal "Node", members[0].member_type
    assert_equal member_node.id, members[0].member_id
    assert_equal "some way", members[1].member_role
    assert_equal "Way", members[1].member_type
    assert_equal member_way.id, members[1].member_id
    assert_equal "some relation", members[2].member_role
    assert_equal "Relation", members[2].member_type
    assert_equal member_relation.id, members[2].member_id
  end

  def test_relations
    old_relation_v1 = create(:old_relation)
    old_relation_v2 = create(:old_relation, :current_relation => old_relation_v1.current_relation, :version => 2)
    old_relation_v3 = create(:old_relation, :current_relation => old_relation_v1.current_relation, :version => 3)
    old_relation_v4 = create(:old_relation, :current_relation => old_relation_v1.current_relation, :version => 4)
    member_node = create(:node)
    member_way = create(:way)
    member_relation = create(:relation)
    create(:old_relation_member, :old_relation => old_relation_v1, :member => member_node, :member_role => "some node")
    create(:old_relation_member, :old_relation => old_relation_v2, :member => member_node, :member_role => "some changed node")
    create(:old_relation_member, :old_relation => old_relation_v3, :member => member_node, :member_role => "some changed node")
    create(:old_relation_member, :old_relation => old_relation_v3, :member => member_relation, :member_role => "some relation")
    create(:old_relation_member, :old_relation => old_relation_v4, :member => member_node, :member_role => "some node")
    create(:old_relation_member, :old_relation => old_relation_v4, :member => member_way, :member_role => "some way")
    create(:old_relation_member, :old_relation => old_relation_v4, :member => member_relation, :member_role => "some relation")

    members = OldRelation.find(old_relation_v1.id).members
    assert_equal 1, members.count
    assert_equal ["Node", member_node.id, "some node"], members[0]

    members = OldRelation.find(old_relation_v2.id).members
    assert_equal 1, members.count
    assert_equal ["Node", member_node.id, "some changed node"], members[0]

    members = OldRelation.find(old_relation_v3.id).members
    assert_equal 2, members.count
    assert_equal ["Node", member_node.id, "some changed node"], members[0]
    assert_equal ["Relation", member_relation.id, "some relation"], members[1]

    members = OldRelation.find(old_relation_v4.id).members
    assert_equal 3, members.count
    assert_equal ["Node", member_node.id, "some node"], members[0]
    assert_equal ["Way", member_way.id, "some way"], members[1]
    assert_equal ["Relation", member_relation.id, "some relation"], members[2]
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
