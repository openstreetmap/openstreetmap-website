require "test_helper"

class OldWayTest < ActiveSupport::TestCase
  def test_old_nodes
    old_way_v1 = create(:old_way, :version => 1)
    old_way_v2 = create(:old_way, :current_way => old_way_v1.current_way, :version => 2)
    node1 = create(:node)
    node2 = create(:node)
    node3 = create(:node)
    create(:old_way_node, :old_way => old_way_v1, :node => node1, :sequence_id => 1)
    create(:old_way_node, :old_way => old_way_v1, :node => node2, :sequence_id => 2)
    create(:old_way_node, :old_way => old_way_v2, :node => node1, :sequence_id => 1)
    create(:old_way_node, :old_way => old_way_v2, :node => node3, :sequence_id => 2)
    create(:old_way_node, :old_way => old_way_v2, :node => node2, :sequence_id => 3)

    nodes = OldWay.find(old_way_v1.id).old_nodes.order(:sequence_id)
    assert_equal 2, nodes.count
    assert_equal node1.id, nodes[0].node_id
    assert_equal node2.id, nodes[1].node_id

    nodes = OldWay.find(old_way_v2.id).old_nodes.order(:sequence_id)
    assert_equal 3, nodes.count
    assert_equal node1.id, nodes[0].node_id
    assert_equal node3.id, nodes[1].node_id
    assert_equal node2.id, nodes[2].node_id
  end

  def test_nds
    old_way_v1 = create(:old_way, :version => 1)
    old_way_v2 = create(:old_way, :current_way => old_way_v1.current_way, :version => 2)
    node1 = create(:node)
    node2 = create(:node)
    node3 = create(:node)
    create(:old_way_node, :old_way => old_way_v1, :node => node1, :sequence_id => 1)
    create(:old_way_node, :old_way => old_way_v1, :node => node2, :sequence_id => 2)
    create(:old_way_node, :old_way => old_way_v2, :node => node1, :sequence_id => 1)
    create(:old_way_node, :old_way => old_way_v2, :node => node3, :sequence_id => 2)
    create(:old_way_node, :old_way => old_way_v2, :node => node2, :sequence_id => 3)

    nodes = OldWay.find(old_way_v1.id).nds
    assert_equal 2, nodes.count
    assert_equal [node1.id, node2.id], nodes

    nodes = OldWay.find(old_way_v2.id).nds
    assert_equal 3, nodes.count
    assert_equal [node1.id, node3.id, node2.id], nodes
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
    way = create(:way, :with_history, :version => 4)
    way_v3 = way.old_ways.find_by(:version => 3)
    way_v4 = way.old_ways.find_by(:version => 4)
    node_a = create(:node, :with_history, :version => 4)
    node_b = create(:node, :with_history, :version => 3)
    node_c = create(:node, :with_history, :version => 2)
    node_d = create(:node, :with_history, :deleted, :version => 1)
    create(:old_way_node, :old_way => way_v3, :node => node_a, :sequence_id => 1)
    create(:old_way_node, :old_way => way_v3, :node => node_b, :sequence_id => 2)
    create(:old_way_node, :old_way => way_v4, :node => node_c, :sequence_id => 1)
    node_tag = create(:node_tag, :node => node_a)
    node_tag2 = create(:node_tag, :node => node_b)
    node_tag3 = create(:node_tag, :node => node_d)

    nodes = OldWay.find(way_v3.id).get_nodes_undelete
    assert_equal 2, nodes.size
    assert_equal [node_a.lon, node_a.lat, node_a.id, node_a.version, { node_tag.k => node_tag.v }, true], nodes[0]
    assert_equal [node_b.lon, node_b.lat, node_b.id, node_b.version, { node_tag2.k => node_tag2.v }, true], nodes[1]

    redacted_way = create(:way, :with_history, :version => 3)
    redacted_way_v2 = redacted_way.old_ways.find_by(:version => 2)
    redacted_way_v3 = redacted_way.old_ways.find_by(:version => 3)
    create(:old_way_node, :old_way => redacted_way_v2, :node => node_b, :sequence_id => 1)
    create(:old_way_node, :old_way => redacted_way_v2, :node => node_d, :sequence_id => 2)
    create(:old_way_node, :old_way => redacted_way_v3, :node => node_c, :sequence_id => 1)
    redacted_way_v2.redact!(create(:redaction))

    nodes = OldWay.find(redacted_way_v2.id).get_nodes_undelete
    assert_equal 2, nodes.size
    assert_equal [node_b.lon, node_b.lat, node_b.id, node_b.version, { node_tag2.k => node_tag2.v }, true], nodes[0]
    assert_equal [node_d.lon, node_d.lat, node_d.id, node_d.version, { node_tag3.k => node_tag3.v }, false], nodes[1]
  end
end
