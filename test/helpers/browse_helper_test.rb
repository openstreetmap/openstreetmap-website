# frozen_string_literal: true

require "test_helper"

class BrowseHelperTest < ActionView::TestCase

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
    assert_equal "<del>test</del>", redacted_output

    deleted_output = element_strikethrough(create(:node, :deleted)) { "test" }
    assert_equal "<del>test</del>", deleted_output
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
    icon_dom = parse_html(icon)
    assert_dom icon_dom, "img:root", :count => 1 do
      assert_dom "> @title", 0
    end

    icon = element_icon("node", create(:node, :deleted))
    icon_dom = parse_html(icon)
    assert_dom icon_dom, "img:root", :count => 1 do
      assert_dom "> @title", 0
    end

    icon = element_icon("node", node)
    icon_dom = parse_html(icon)
    assert_dom icon_dom, "img:root", :count => 1 do
      assert_dom "> @title", "building=yes, shop=gift, and tourism=museum"
    end

    icon = element_icon("node", node_v2)
    icon_dom = parse_html(icon)
    assert_dom icon_dom, "img:root", :count => 1 do
      assert_dom "> @title", "building=yes, shop=gift, and tourism=museum"
    end

    icon = element_icon("node", node_v1)
    icon_dom = parse_html(icon)
    assert_dom icon_dom, "img:root", :count => 1 do
      assert_dom "> @title", 0
    end
  end

  def test_format_key
    html = format_key("highway")
    assert_dom_equal "<a href=\"https://wiki.openstreetmap.org/wiki/Key:highway?uselang=en\" title=\"The wiki description page for the highway tag\">highway</a>", html

    html = format_key("unknown")
    assert_dom_equal "unknown", html
  end

  def test_format_value
    html = format_value("highway", "primary")
    assert_dom_equal "<a href=\"https://wiki.openstreetmap.org/wiki/Tag:highway=primary?uselang=en\" title=\"The wiki description page for the highway=primary tag\">primary</a>", html

    html = format_value("highway", "unknown")
    assert_dom_equal "unknown", html

    html = format_value("unknown", "unknown")
    assert_dom_equal "unknown", html

    html = format_value("unknown", "abc;def")
    assert_dom_equal "abc;def", html

    html = format_value("unknown", "foo;")
    assert_dom_equal "foo;", html

    html = format_value("addr:street", "Rue de l'Amigo")
    assert_dom_equal "Rue de l&#39;Amigo", html

    html = format_value("phone", "+1234567890")
    assert_dom_equal "<a href=\"tel:+1234567890\" title=\"Call +1234567890\">+1234567890</a>", html

    html = format_value("phone", "+1 (234) 567-890 ;  +22334455")
    assert_dom_equal "<a href=\"tel:+1(234)567-890\" title=\"Call +1 (234) 567-890\">+1 (234) 567-890</a>; <a href=\"tel:+22334455\" title=\"Call +22334455\">+22334455</a>", html

    html = format_value("wikipedia", "en:Test")
    assert_dom_equal "<a title=\"The en:Test article on Wikipedia\" href=\"https://en.wikipedia.org/wiki/Test?uselang=en\">en:Test</a>", html

    html = format_value("wikipedia", "de:Berlin;en:London")
    assert_dom_equal "<a title=\"The de:Berlin article on Wikipedia\" href=\"https://de.wikipedia.org/wiki/Berlin?uselang=en\">de:Berlin</a>;<a title=\"The en:London article on Wikipedia\" href=\"https://en.wikipedia.org/wiki/London?uselang=en\">en:London</a>",
                     html

    html = format_value("wikidata", "Q42")
    dom = parse_html html
    assert_select dom, "a[title='The Q42 item on Wikidata'][href$='www.wikidata.org/entity/Q42?uselang=en']", :text => "Q42"
    assert_select dom, "button.wdt-preview>svg>path[fill]", 1

    html = format_value("operator:wikidata", "Q12;Q98")
    dom = parse_html html
    assert_select dom, "a[title='The Q12 item on Wikidata'][href$='www.wikidata.org/entity/Q12?uselang=en']", :text => "Q12"
    assert_select dom, "a[title='The Q98 item on Wikidata'][href$='www.wikidata.org/entity/Q98?uselang=en']", :text => "Q98"
    assert_select dom, "button.wdt-preview>svg>path[fill]", 1

    html = format_value("name:etymology:wikidata", "Q123")
    dom = parse_html html
    assert_select dom, "a[title='The Q123 item on Wikidata'][href$='www.wikidata.org/entity/Q123?uselang=en']", :text => "Q123"
    assert_select dom, "button.wdt-preview>svg>path[fill]", 1

    html = format_value("wikimedia_commons", "File:Test.jpg")
    assert_dom_equal "<a title=\"The File:Test.jpg item on Wikimedia Commons\" href=\"//commons.wikimedia.org/wiki/File:Test.jpg?uselang=en\">File:Test.jpg</a>", html

    html = format_value("mapillary", "123;https://example.com")
    assert_dom_equal "<a rel=\"nofollow\" href=\"https://www.mapillary.com/app/?pKey=123\">123</a>;<a href=\"https://example.com\" rel=\"nofollow\" dir=\"auto\">https://example.com</a>",
                     html

    html = format_value("colour", "#f00")
    dom = parse_html html
    assert_select dom, "svg>rect>@fill", "#f00"
    assert_match(/#f00$/, html)

    html = format_value("email", "foo@example.com")
    assert_dom_equal "<a title=\"Email foo@example.com\" href=\"mailto:foo@example.com\">foo@example.com</a>", html

    html = format_value("opening_hours", "Mo-Fr 09:00-12:00;Sa 09:00-17:00")
    dom = parse_html html
    assert_select dom, "a", 1
    assert_select dom, "a[rel='nofollow']",
                  :text => "Mo-Fr 09:00-12:00;Sa 09:00-17:00"

    html = format_value("website", "https://example.com")
    assert_dom_equal "<a href=\"https://example.com\" rel=\"nofollow\" dir=\"auto\">https://example.com</a>", html

    html = format_value("website", "https://example.com;hello;https://example.net")
    assert_dom_equal "<a href=\"https://example.com\" rel=\"nofollow\" dir=\"auto\">https://example.com</a>;hello;<a href=\"https://example.net\" rel=\"nofollow\" dir=\"auto\">https://example.net</a>", html

    html = format_value("website", "https://routing.openstreetmap.de/routed-car/route/v1/driving/-3.68,57.63;-3.68,57.61")
    dom = parse_html html
    assert_select dom, "a", 1

    html = format_value("website", "example.com/page")
    assert_dom_equal "example.com/page", html
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
