require "test_helper"

class OldWayTest < ActiveSupport::TestCase
  api_fixtures

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
    old_way_v1 = create(:old_way, :version => 1)
    old_way_v2 = create(:old_way, :current_way => old_way_v1.current_way, :version => 2)
    old_way_v3 = create(:old_way, :current_way => old_way_v1.current_way, :version => 3)
    old_way_v4 = create(:old_way, :current_way => old_way_v1.current_way, :version => 4)
    taglist_v3 = create_list(:old_way_tag, 3, :old_way => old_way_v3)
    taglist_v4 = create_list(:old_way_tag, 2, :old_way => old_way_v4)

    tags = OldWay.find(old_way_v1.id).old_tags.order(:k)
    assert_equal 0, tags.count

    tags = OldWay.find(old_way_v2.id).old_tags.order(:k)
    assert_equal 0, tags.count

    tags = OldWay.find(old_way_v3.id).old_tags.order(:k)
    assert_equal taglist_v3.count, tags.count
    taglist_v3.sort_by!(&:k).each_index do |i|
      assert_equal taglist_v3[i].k, tags[i].k
      assert_equal taglist_v3[i].v, tags[i].v
    end

    tags = OldWay.find(old_way_v4.id).old_tags.order(:k)
    assert_equal taglist_v4.count, tags.count
    taglist_v4.sort_by!(&:k).each_index do |i|
      assert_equal taglist_v4[i].k, tags[i].k
      assert_equal taglist_v4[i].v, tags[i].v
    end
  end

  def test_tags
    old_way_v1 = create(:old_way, :version => 1)
    old_way_v2 = create(:old_way, :current_way => old_way_v1.current_way, :version => 2)
    old_way_v3 = create(:old_way, :current_way => old_way_v1.current_way, :version => 3)
    old_way_v4 = create(:old_way, :current_way => old_way_v1.current_way, :version => 4)
    taglist_v3 = create_list(:old_way_tag, 3, :old_way => old_way_v3)
    taglist_v4 = create_list(:old_way_tag, 2, :old_way => old_way_v4)

    tags = OldWay.find(old_way_v1.id).tags
    assert_equal 0, tags.size

    tags = OldWay.find(old_way_v2.id).tags
    assert_equal 0, tags.size

    tags = OldWay.find(old_way_v3.id).tags
    assert_equal taglist_v3.count, tags.count
    taglist_v3.each do |tag|
      assert_equal tag.v, tags[tag.k]
    end

    tags = OldWay.find(old_way_v4.id).tags
    assert_equal taglist_v4.count, tags.count
    taglist_v4.each do |tag|
      assert_equal tag.v, tags[tag.k]
    end
  end

  def test_get_nodes_undelete
    way = ways(:way_with_versions_v3)
    node_tag = create(:node_tag, :node => current_nodes(:node_with_versions))
    node_tag2 = create(:node_tag, :node => current_nodes(:used_node_1))
    nodes = OldWay.find(way.id).get_nodes_undelete
    assert_equal 2, nodes.size
    assert_equal [1.0, 1.0, 15, 4, { node_tag.k => node_tag.v }, true], nodes[0]
    assert_equal [3.0, 3.0, 3, 1, { node_tag2.k => node_tag2.v }, true], nodes[1]

    way = ways(:way_with_redacted_versions_v2)
    node_tag3 = create(:node_tag, :node => current_nodes(:invisible_node))
    nodes = OldWay.find(way.id).get_nodes_undelete
    assert_equal 2, nodes.size
    assert_equal [3.0, 3.0, 3, 1, { node_tag2.k => node_tag2.v }, true], nodes[0]
    assert_equal [2.0, 2.0, 2, 1, { node_tag3.k => node_tag3.v }, false], nodes[1]
  end
end
