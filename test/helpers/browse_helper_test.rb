# coding: utf-8
require "test_helper"

class BrowseHelperTest < ActionView::TestCase
  include ERB::Util
  include ApplicationHelper

  def test_printable_name
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

    assert_dom_equal deleted_node.id.to_s, printable_name(deleted_node)
    assert_dom_equal "<bdi>Test Node</bdi> (<bdi>#{node.id}</bdi>)", printable_name(node)
    assert_dom_equal "<bdi>Test Node</bdi> (<bdi>#{node.id}</bdi>)", printable_name(node_v2)
    assert_dom_equal node.id.to_s, printable_name(node_v1)
    assert_dom_equal "<bdi>Test Node</bdi> (<bdi>#{node.id}, v2</bdi>)", printable_name(node_v2, :version => true)
    assert_dom_equal "#{node.id}, v1", printable_name(node_v1, :version => true)
    assert_dom_equal "<bdi>3.1415926</bdi> (<bdi>#{node_with_ref_without_name.id}</bdi>)", printable_name(node_with_ref_without_name)

    I18n.with_locale "pt" do
      assert_dom_equal deleted_node.id.to_s, printable_name(deleted_node)
      assert_dom_equal "<bdi>Nó teste</bdi> (<bdi>#{node.id}</bdi>)", printable_name(node)
      assert_dom_equal "<bdi>Nó teste</bdi> (<bdi>#{node.id}</bdi>)", printable_name(node_v2)
      assert_dom_equal node.id.to_s, printable_name(node_v1)
      assert_dom_equal "<bdi>Nó teste</bdi> (<bdi>#{node.id}, v2</bdi>)", printable_name(node_v2, :version => true)
      assert_dom_equal "#{node.id}, v1", printable_name(node_v1, :version => true)
      assert_dom_equal "<bdi>3.1415926</bdi> (<bdi>#{node_with_ref_without_name.id}</bdi>)", printable_name(node_with_ref_without_name)
    end

    I18n.with_locale "pt-BR" do
      assert_dom_equal deleted_node.id.to_s, printable_name(deleted_node)
      assert_dom_equal "<bdi>Nó teste</bdi> (<bdi>#{node.id}</bdi>)", printable_name(node)
      assert_dom_equal "<bdi>Nó teste</bdi> (<bdi>#{node.id}</bdi>)", printable_name(node_v2)
      assert_dom_equal node.id.to_s, printable_name(node_v1)
      assert_dom_equal "<bdi>Nó teste</bdi> (<bdi>#{node.id}, v2</bdi>)", printable_name(node_v2, :version => true)
      assert_dom_equal "#{node.id}, v1", printable_name(node_v1, :version => true)
      assert_dom_equal "<bdi>3.1415926</bdi> (<bdi>#{node_with_ref_without_name.id}</bdi>)", printable_name(node_with_ref_without_name)
    end

    I18n.with_locale "de" do
      assert_dom_equal deleted_node.id.to_s, printable_name(deleted_node)
      assert_dom_equal "<bdi>Test Node</bdi> (<bdi>#{node.id}</bdi>)", printable_name(node)
      assert_dom_equal "<bdi>Test Node</bdi> (<bdi>#{node.id}</bdi>)", printable_name(node_v2)
      assert_dom_equal node.id.to_s, printable_name(node_v1)
      assert_dom_equal "<bdi>Test Node</bdi> (<bdi>#{node.id}, v2</bdi>)", printable_name(node_v2, :version => true)
      assert_dom_equal "#{node.id}, v1", printable_name(node_v1, :version => true)
      assert_dom_equal "<bdi>3.1415926</bdi> (<bdi>#{node_with_ref_without_name.id}</bdi>)", printable_name(node_with_ref_without_name)
    end
  end

  def test_link_class
    node = create(:node, :with_history, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v2 = node.old_nodes.find_by(:version => 2)
    node_v1.redact!(create(:redaction))

    add_tags_selection(node)
    add_old_tags_selection(node_v2)
    add_old_tags_selection(node_v1)

    assert_equal "node", link_class("node", create(:node))
    assert_equal "node deleted", link_class("node", create(:node, :deleted))

    assert_equal "node building yes shop gift tourism museum", link_class("node", node)
    assert_equal "node building yes shop gift tourism museum", link_class("node", node_v2)
    assert_equal "node deleted", link_class("node", node_v1)
  end

  def test_link_title
    node = create(:node, :with_history, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v2 = node.old_nodes.find_by(:version => 2)
    node_v1.redact!(create(:redaction))

    add_tags_selection(node)
    add_old_tags_selection(node_v2)
    add_old_tags_selection(node_v1)

    assert_equal "", link_title(create(:node))
    assert_equal "", link_title(create(:node, :deleted))

    assert_equal "building=yes, shop=gift, and tourism=museum", link_title(node)
    assert_equal "building=yes, shop=gift, and tourism=museum", link_title(node_v2)
    assert_equal "", link_title(node_v1)
  end

  def test_icon_tags
    node = create(:node, :with_history, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v2 = node.old_nodes.find_by(:version => 2)
    node_v1.redact!(create(:redaction))

    add_tags_selection(node)

    tags = icon_tags(node)
    assert_equal 3, tags.count
    assert_includes tags, %w[building yes]
    assert_includes tags, %w[tourism museum]
    assert_includes tags, %w[shop gift]

    add_old_tags_selection(node_v2)
    add_old_tags_selection(node_v1)

    tags = icon_tags(node_v2)
    assert_equal 3, tags.count
    assert_includes tags, %w[building yes]
    assert_includes tags, %w[tourism museum]
    assert_includes tags, %w[shop gift]

    tags = icon_tags(node_v1)
    assert_equal 3, tags.count
    assert_includes tags, %w[building yes]
    assert_includes tags, %w[tourism museum]
    assert_includes tags, %w[shop gift]
  end

  def test_tags_with_version_info
    node = create(:node, :with_history, :version => 3)
    add_current_tag(node, 1, "building", "yes")
    add_tag(node, 2, "name", "Nowhere")
    add_tag(node, 2, "other", "something")
    add_current_tag(node, 3, "name", "The Place")

    version_info = tags_with_version_info(node.node_tags, node.old_nodes)
    assert_equal 1, version_info["building"][1][:version]
    assert_equal 3, version_info["name"][1][:version]
    assert_nil version_info["other"]
  end

  private

  def add_tag(node, version, k, v)
    create(:old_node_tag, :old_node => node.old_nodes.find_by(:version => version), :k => k, :v => v)
  end

  def add_current_tag(node, version, k, v)
    add_tag(node, version, k, v)
    create(:node_tag, :node => node, :k => k, :v => v)
  end

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
