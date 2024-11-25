require "test_helper"

class BrowseHelperTest < ActionView::TestCase
  include ERB::Util
  include ApplicationHelper

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
