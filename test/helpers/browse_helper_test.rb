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

  def test_element_class
    node = create(:node, :with_history, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v2 = node.old_nodes.find_by(:version => 2)
    node_v1.redact!(create(:redaction))

    add_tags_selection(node)
    add_old_tags_selection(node_v2)
    add_old_tags_selection(node_v1)

    assert_equal "node", element_class("node", create(:node))
    assert_equal "node", element_class("node", create(:node, :deleted))

    assert_equal "node building yes shop gift tourism museum", element_class("node", node)
    assert_equal "node building yes shop gift tourism museum", element_class("node", node_v2)
    assert_equal "node", element_class("node", node_v1)
  end

  def test_element_title
    node = create(:node, :with_history, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v2 = node.old_nodes.find_by(:version => 2)
    node_v1.redact!(create(:redaction))

    add_tags_selection(node)
    add_old_tags_selection(node_v2)
    add_old_tags_selection(node_v1)

    assert_equal "", element_title(create(:node))
    assert_equal "", element_title(create(:node, :deleted))

    assert_equal "building=yes, shop=gift, and tourism=museum", element_title(node)
    assert_equal "building=yes, shop=gift, and tourism=museum", element_title(node_v2)
    assert_equal "", element_title(node_v1)
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

  def test_svg_files_valid
    BROWSE_IMAGE.each_value do |value|
      assert_path_exists "app/assets/images/browse/#{value[:image].split('#').first}"
    end
  end

  def test_svg_element_single_current_link
    # Test if node returns svg as per config/browse_image.yml
    node = create(:node, :version => 1)
    create(:node_tag, :node => node, :k => "amenity", :v => "bench")
    html = element_single_current_link "node", node
    root = Nokogiri::HTML::DocumentFragment.parse(html)
    assert_select root, "a[@class='node']" do
      validate_svg
    end
  end

  def test_svg_element_list_item
    # Test if node returns svg as per config/browse_image.yml
    node = create(:node, :version => 1)
    create(:node_tag, :node => node, :k => "amenity", :v => "bench")
    html = element_list_item "node", node do
      "Dummy hyperlink to a node"
    end
    root = Nokogiri::HTML::DocumentFragment.parse(html)
    assert_select root, "li[@class='node']" do
      validate_svg
    end
  end

  private

  def validate_svg
    assert_select "svg", :count => 1
    assert_select "svg[@class='man-made svg_icon default']", :count => 1
    assert_select "svg[@xmlns='http://www.w3.org/2000/svg']", :count => 1
    assert_select "svg" do
      assert_select "use[@href='/images/browse/amenity_bench.svg#icon']", :count => 1
    end
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
