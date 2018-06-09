require "test_helper"

class OldNodeTest < ActiveSupport::TestCase
  def test_node_too_far_north
    node = build(:old_node, :latitude => 90.01 * OldNode::SCALE)
    assert_equal false, node.valid?
  end

  def test_node_north_limit
    node = build(:old_node, :latitude => 90 * OldNode::SCALE)
    assert node.valid?
  end

  def test_node_too_far_south
    node = build(:old_node, :latitude => -90.01 * OldNode::SCALE)
    assert_equal false, node.valid?
  end

  def test_node_south_limit
    node = build(:old_node, :latitude => -90 * OldNode::SCALE)
    assert node.valid?
  end

  def test_node_too_far_west
    node = build(:old_node, :longitude => -180.01 * OldNode::SCALE)
    assert_equal false, node.valid?
  end

  def test_node_west_limit
    node = build(:old_node, :longitude => -180 * OldNode::SCALE)
    assert node.valid?
  end

  def test_node_too_far_east
    node = build(:old_node, :longitude => 180.01 * OldNode::SCALE)
    assert_equal false, node.valid?
  end

  def test_node_east_limit
    node = build(:old_node, :longitude => 180 * OldNode::SCALE)
    assert node.valid?
  end

  def test_totally_wrong
    node = build(:old_node, :latitude => 200 * OldNode::SCALE, :longitude => 200 * OldNode::SCALE)
    assert_equal false, node.valid?
  end

  def test_lat_lon
    node = build(:old_node, :latitude => 12.345 * OldNode::SCALE, :longitude => 34.567 * OldNode::SCALE)

    assert_in_delta 12.345, node.lat, 0.0000001
    assert_in_delta 34.567, node.lon, 0.0000001

    node.lat = 54.321
    node.lon = 76.543

    assert_in_delta 54.321 * OldNode::SCALE, node.latitude, 0.000001
    assert_in_delta 76.543 * OldNode::SCALE, node.longitude, 0.000001
  end

  # Ensure the lat/lon is formatted as a decimal e.g. not 4.0e-05
  def test_lat_lon_xml_format
    old_node = build(:old_node, :latitude => 0.00004 * OldNode::SCALE, :longitude => 0.00008 * OldNode::SCALE)

    assert_match(/lat="0.0000400"/, old_node.to_xml.to_s)
    assert_match(/lon="0.0000800"/, old_node.to_xml.to_s)
  end

  def test_node_tags
    node_v1 = create(:old_node, :version => 1)
    node_v2 = create(:old_node, :node_id => node_v1.node_id, :version => 2)
    node_v3 = create(:old_node, :node_id => node_v1.node_id, :version => 3)
    node_v4 = create(:old_node, :node_id => node_v1.node_id, :version => 4)
    taglist_v3 = create_list(:old_node_tag, 3, :old_node => node_v3)
    taglist_v4 = create_list(:old_node_tag, 2, :old_node => node_v4)

    node = node_v1
    tags = OldNode.find(node.id).old_tags.order(:k)
    assert_equal 0, tags.count

    node = node_v2
    tags = OldNode.find(node.id).old_tags.order(:k)
    assert_equal 0, tags.count

    node = node_v3
    tags = OldNode.find(node.id).old_tags.order(:k)
    assert_equal taglist_v3.count, tags.count
    taglist_v3.sort_by!(&:k).each_index do |i|
      assert_equal taglist_v3[i].k, tags[i].k
      assert_equal taglist_v3[i].v, tags[i].v
    end

    node = node_v4
    tags = OldNode.find(node.id).old_tags.order(:k)
    assert_equal taglist_v4.count, tags.count
    taglist_v4.sort_by!(&:k).each_index do |i|
      assert_equal taglist_v4[i].k, tags[i].k
      assert_equal taglist_v4[i].v, tags[i].v
    end
  end

  def test_tags
    node_v1 = create(:old_node, :version => 1)
    node_v2 = create(:old_node, :node_id => node_v1.node_id, :version => 2)
    node_v3 = create(:old_node, :node_id => node_v1.node_id, :version => 3)
    node_v4 = create(:old_node, :node_id => node_v1.node_id, :version => 4)
    taglist_v3 = create_list(:old_node_tag, 3, :old_node => node_v3)
    taglist_v4 = create_list(:old_node_tag, 2, :old_node => node_v4)

    node = node_v1
    tags = OldNode.find(node.id).tags
    assert_equal 0, tags.size

    node = node_v2
    tags = OldNode.find(node.id).tags
    assert_equal 0, tags.size

    node = node_v3
    tags = OldNode.find(node.id).tags
    assert_equal taglist_v3.count, tags.count
    taglist_v3.each do |tag|
      assert_equal tag.v, tags[tag.k]
    end

    node = node_v4
    tags = OldNode.find(node.id).tags
    assert_equal taglist_v4.count, tags.count
    taglist_v4.each do |tag|
      assert_equal tag.v, tags[tag.k]
    end
  end
end
