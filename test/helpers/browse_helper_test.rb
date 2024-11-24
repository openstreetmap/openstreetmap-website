require "test_helper"

class BrowseHelperTest < ActionView::TestCase
  include ERB::Util
  include ApplicationHelper

  def test_group_way_nodes_one_node
    way = create(:way_with_nodes, :nodes_count => 1)

    assert_equal [
      { :nodes => [way.nodes[0]], :related_ways => [] }
    ], group_way_nodes(way)
  end

  def test_group_way_nodes_two_untagged_nodes
    way = create(:way_with_nodes, :nodes_count => 2)

    assert_equal [
      { :nodes => [way.nodes[0], way.nodes[1]], :related_ways => [] }
    ], group_way_nodes(way)
  end

  def test_group_way_nodes_two_tagged_nodes
    way = create(:way_with_nodes, :nodes_count => 2)
    create(:node_tag, :node => way.nodes[0], :k => "name", :v => "Distinct Node 0")
    create(:node_tag, :node => way.nodes[1], :k => "name", :v => "Distinct Node 1")

    assert_equal [
      { :nodes => [way.nodes[0]], :related_ways => [] },
      { :nodes => [way.nodes[1]], :related_ways => [] }
    ], group_way_nodes(way)
  end

  #
  # (b)--1--(a)--2--(c)
  #
  def test_group_way_nodes_shared_with_one_way
    way1 = create(:way)
    way2 = create(:way)
    node_a = create(:node)
    node_b = create(:node)
    node_c = create(:node)
    create(:way_node, :way => way1, :node => node_a, :sequence_id => 1)
    create(:way_node, :way => way1, :node => node_b, :sequence_id => 2)
    create(:way_node, :way => way2, :node => node_a, :sequence_id => 1)
    create(:way_node, :way => way2, :node => node_c, :sequence_id => 2)

    assert_equal [
      { :nodes => [node_a], :related_ways => [way2] },
      { :nodes => [node_b], :related_ways => [] }
    ], group_way_nodes(way1)
    assert_equal [
      { :nodes => [node_a], :related_ways => [way1] },
      { :nodes => [node_c], :related_ways => [] }
    ], group_way_nodes(way2)
  end

  #
  # (b)--1--(a)--2--(c)
  #           \    /
  #            \  /
  #            (d)
  #
  def test_group_way_nodes_shared_with_one_looped_way
    way1 = create(:way)
    way2 = create(:way)
    node_a = create(:node)
    node_b = create(:node)
    node_c = create(:node)
    node_d = create(:node)
    create(:way_node, :way => way1, :node => node_a, :sequence_id => 1)
    create(:way_node, :way => way1, :node => node_b, :sequence_id => 2)
    create(:way_node, :way => way2, :node => node_a, :sequence_id => 1)
    create(:way_node, :way => way2, :node => node_c, :sequence_id => 2)
    create(:way_node, :way => way2, :node => node_d, :sequence_id => 3)
    create(:way_node, :way => way2, :node => node_a, :sequence_id => 4)

    assert_equal [
      { :nodes => [node_a], :related_ways => [way2] },
      { :nodes => [node_b], :related_ways => [] }
    ], group_way_nodes(way1)
    assert_equal [
      { :nodes => [node_a], :related_ways => [way1] },
      { :nodes => [node_c, node_d], :related_ways => [] },
      { :nodes => [node_a], :related_ways => [way1] }
    ], group_way_nodes(way2)
  end

  #
  # (b)--1--(a)--2--(c)
  #           \
  #            3
  #             \
  #             (d)
  #
  def test_group_way_nodes_shared_with_two_ways
    way1 = create(:way)
    way2 = create(:way)
    way3 = create(:way)
    node_a = create(:node)
    node_b = create(:node)
    node_c = create(:node)
    node_d = create(:node)
    create(:way_node, :way => way1, :node => node_a, :sequence_id => 1)
    create(:way_node, :way => way1, :node => node_b, :sequence_id => 2)
    create(:way_node, :way => way2, :node => node_a, :sequence_id => 1)
    create(:way_node, :way => way2, :node => node_c, :sequence_id => 2)
    create(:way_node, :way => way3, :node => node_a, :sequence_id => 1)
    create(:way_node, :way => way3, :node => node_d, :sequence_id => 2)

    assert_equal [
      { :nodes => [node_a], :related_ways => [way2, way3] },
      { :nodes => [node_b], :related_ways => [] }
    ], group_way_nodes(way1)
    assert_equal [
      { :nodes => [node_a], :related_ways => [way1, way3] },
      { :nodes => [node_c], :related_ways => [] }
    ], group_way_nodes(way2)
    assert_equal [
      { :nodes => [node_a], :related_ways => [way1, way2] },
      { :nodes => [node_d], :related_ways => [] }
    ], group_way_nodes(way3)
  end

  def test_printable_element_name
    node = create(:node, :with_history, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v2 = node.old_nodes.find_by(:version => 2)
    node_v1.redact!(create(:redaction))

    add_tags_selection(node)
    add_old_tags_selection(node_v2)
    add_old_tags_selection(node_v1)

    node_with_ref_without_name = create(:node)
    create(:node_tag, :node => node_with_ref_without_name, :k => "ref", :v => "3.1415926")

    deleted_node = create(:node, :deleted)

    assert_dom_equal deleted_node.id.to_s, printable_element_name(deleted_node)
    assert_dom_equal "<bdi>Test Node</bdi> (<bdi>#{node.id}</bdi>)", printable_element_name(node)
    assert_dom_equal "<bdi>Test Node</bdi> (<bdi>#{node.id}</bdi>)", printable_element_name(node_v2)
    assert_dom_equal node.id.to_s, printable_element_name(node_v1)
    assert_dom_equal "<bdi>3.1415926</bdi> (<bdi>#{node_with_ref_without_name.id}</bdi>)", printable_element_name(node_with_ref_without_name)

    I18n.with_locale "pt" do
      assert_dom_equal deleted_node.id.to_s, printable_element_name(deleted_node)
      assert_dom_equal "<bdi>Nó teste</bdi> (<bdi>#{node.id}</bdi>)", printable_element_name(node)
      assert_dom_equal "<bdi>Nó teste</bdi> (<bdi>#{node.id}</bdi>)", printable_element_name(node_v2)
      assert_dom_equal node.id.to_s, printable_element_name(node_v1)
      assert_dom_equal "<bdi>3.1415926</bdi> (<bdi>#{node_with_ref_without_name.id}</bdi>)", printable_element_name(node_with_ref_without_name)
    end

    I18n.with_locale "pt-BR" do
      assert_dom_equal deleted_node.id.to_s, printable_element_name(deleted_node)
      assert_dom_equal "<bdi>Nó teste</bdi> (<bdi>#{node.id}</bdi>)", printable_element_name(node)
      assert_dom_equal "<bdi>Nó teste</bdi> (<bdi>#{node.id}</bdi>)", printable_element_name(node_v2)
      assert_dom_equal node.id.to_s, printable_element_name(node_v1)
      assert_dom_equal "<bdi>3.1415926</bdi> (<bdi>#{node_with_ref_without_name.id}</bdi>)", printable_element_name(node_with_ref_without_name)
    end

    I18n.with_locale "de" do
      assert_dom_equal deleted_node.id.to_s, printable_element_name(deleted_node)
      assert_dom_equal "<bdi>Test Node</bdi> (<bdi>#{node.id}</bdi>)", printable_element_name(node)
      assert_dom_equal "<bdi>Test Node</bdi> (<bdi>#{node.id}</bdi>)", printable_element_name(node_v2)
      assert_dom_equal node.id.to_s, printable_element_name(node_v1)
      assert_dom_equal "<bdi>3.1415926</bdi> (<bdi>#{node_with_ref_without_name.id}</bdi>)", printable_element_name(node_with_ref_without_name)
    end
  end

  def test_element_strikethrough
    node = create(:node, :with_history, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v2 = node.old_nodes.find_by(:version => 2)
    node_v1.redact!(create(:redaction))

    normal_output = element_strikethrough(node_v2) { "test" }
    assert_equal "test", normal_output

    redacted_output = element_strikethrough(node_v1) { "test" }
    assert_equal "<s>test</s>", redacted_output

    deleted_output = element_strikethrough(create(:node, :deleted)) { "test" }
    assert_equal "<s>test</s>", deleted_output
  end

  def test_element_icon
    node = create(:node, :with_history, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v2 = node.old_nodes.find_by(:version => 2)
    node_v1.redact!(create(:redaction))

    add_tags_selection(node)
    add_old_tags_selection(node_v2)
    add_old_tags_selection(node_v1)

    icon = element_icon("node", create(:node))
    icon_dom = Rails::Dom::Testing.html_document_fragment.parse(icon)
    assert_dom icon_dom, "img:root", :count => 1 do
      assert_dom "> @title", 0
    end

    icon = element_icon("node", create(:node, :deleted))
    icon_dom = Rails::Dom::Testing.html_document_fragment.parse(icon)
    assert_dom icon_dom, "img:root", :count => 1 do
      assert_dom "> @title", 0
    end

    icon = element_icon("node", node)
    icon_dom = Rails::Dom::Testing.html_document_fragment.parse(icon)
    assert_dom icon_dom, "img:root", :count => 1 do
      assert_dom "> @title", "building=yes, shop=gift, and tourism=museum"
    end

    icon = element_icon("node", node_v2)
    icon_dom = Rails::Dom::Testing.html_document_fragment.parse(icon)
    assert_dom icon_dom, "img:root", :count => 1 do
      assert_dom "> @title", "building=yes, shop=gift, and tourism=museum"
    end

    icon = element_icon("node", node_v1)
    icon_dom = Rails::Dom::Testing.html_document_fragment.parse(icon)
    assert_dom icon_dom, "img:root", :count => 1 do
      assert_dom "> @title", 0
    end
  end

  private

  def add_old_tags_selection(old_node)
    { "building" => "yes",
      "shop" => "gift",
      "tourism" => "museum",
      "name" => "Test Node",
      "name:pt" => "Nó teste" }.each do |key, value|
      create(:old_node_tag, :old_node => old_node, :k => key, :v => value)
    end
  end

  def add_tags_selection(node)
    { "building" => "yes",
      "shop" => "gift",
      "tourism" => "museum",
      "name" => "Test Node",
      "name:pt" => "Nó teste" }.each do |key, value|
      create(:node_tag, :node => node, :k => key, :v => value)
    end
  end

  def preferred_languages
    Locale.list(I18n.locale)
  end
end
