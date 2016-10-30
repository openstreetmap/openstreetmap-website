# -*- coding: utf-8 -*-

require "test_helper"

class BrowseHelperTest < ActionView::TestCase
  include ERB::Util
  include ApplicationHelper

  api_fixtures

  def setup
    I18n.locale = "en"
  end

  def teardown
    I18n.locale = "en"
  end

  def test_printable_name
    add_tags_selection(current_nodes(:node_with_name))
    create(:node_tag, :node => current_nodes(:node_with_ref_without_name), :k => "ref", :v => "3.1415926")
    add_old_tags_selection(nodes(:node_with_name_current_version))
    add_old_tags_selection(nodes(:node_with_name_redacted_version))

    # current_nodes(:redacted_node) is deleted, so has no tags.
    assert_dom_equal "17", printable_name(current_nodes(:redacted_node))
    assert_dom_equal "<bdi>Test Node</bdi> (<bdi>18</bdi>)", printable_name(current_nodes(:node_with_name))
    assert_dom_equal "<bdi>Test Node</bdi> (<bdi>18</bdi>)", printable_name(nodes(:node_with_name_current_version))
    assert_dom_equal "18", printable_name(nodes(:node_with_name_redacted_version))
    assert_dom_equal "<bdi>Test Node</bdi> (<bdi>18, v2</bdi>)", printable_name(nodes(:node_with_name_current_version), true)
    assert_dom_equal "18, v1", printable_name(nodes(:node_with_name_redacted_version), true)
    assert_dom_equal "<bdi>3.1415926</bdi> (<bdi>19</bdi>)", printable_name(current_nodes(:node_with_ref_without_name))

    I18n.locale = "pt"

    assert_dom_equal "17", printable_name(current_nodes(:redacted_node))
    assert_dom_equal "<bdi>Nó teste</bdi> (<bdi>18</bdi>)", printable_name(current_nodes(:node_with_name))
    assert_dom_equal "<bdi>Nó teste</bdi> (<bdi>18</bdi>)", printable_name(nodes(:node_with_name_current_version))
    assert_dom_equal "18", printable_name(nodes(:node_with_name_redacted_version))
    assert_dom_equal "<bdi>Nó teste</bdi> (<bdi>18, v2</bdi>)", printable_name(nodes(:node_with_name_current_version), true)
    assert_dom_equal "18, v1", printable_name(nodes(:node_with_name_redacted_version), true)
    assert_dom_equal "<bdi>3.1415926</bdi> (<bdi>19</bdi>)", printable_name(current_nodes(:node_with_ref_without_name))

    I18n.locale = "pt-BR"

    assert_dom_equal "17", printable_name(current_nodes(:redacted_node))
    assert_dom_equal "<bdi>Nó teste</bdi> (<bdi>18</bdi>)", printable_name(current_nodes(:node_with_name))
    assert_dom_equal "<bdi>Nó teste</bdi> (<bdi>18</bdi>)", printable_name(nodes(:node_with_name_current_version))
    assert_dom_equal "18", printable_name(nodes(:node_with_name_redacted_version))
    assert_dom_equal "<bdi>Nó teste</bdi> (<bdi>18, v2</bdi>)", printable_name(nodes(:node_with_name_current_version), true)
    assert_dom_equal "18, v1", printable_name(nodes(:node_with_name_redacted_version), true)
    assert_dom_equal "<bdi>3.1415926</bdi> (<bdi>19</bdi>)", printable_name(current_nodes(:node_with_ref_without_name))

    I18n.locale = "de"

    assert_dom_equal "17", printable_name(current_nodes(:redacted_node))
    assert_dom_equal "<bdi>Test Node</bdi> (<bdi>18</bdi>)", printable_name(current_nodes(:node_with_name))
    assert_dom_equal "<bdi>Test Node</bdi> (<bdi>18</bdi>)", printable_name(nodes(:node_with_name_current_version))
    assert_dom_equal "18", printable_name(nodes(:node_with_name_redacted_version))
    assert_dom_equal "<bdi>Test Node</bdi> (<bdi>18, v2</bdi>)", printable_name(nodes(:node_with_name_current_version), true)
    assert_dom_equal "18, v1", printable_name(nodes(:node_with_name_redacted_version), true)
    assert_dom_equal "<bdi>3.1415926</bdi> (<bdi>19</bdi>)", printable_name(current_nodes(:node_with_ref_without_name))
  end

  def test_link_class
    add_tags_selection(current_nodes(:node_with_name))

    assert_equal "node", link_class("node", current_nodes(:visible_node))
    assert_equal "node deleted", link_class("node", current_nodes(:invisible_node))
    assert_equal "node deleted", link_class("node", current_nodes(:redacted_node))
    assert_equal "node building yes shop gift tourism museum", link_class("node", current_nodes(:node_with_name))

    add_old_tags_selection(nodes(:node_with_name_current_version))
    add_old_tags_selection(nodes(:node_with_name_redacted_version))
    assert_equal "node building yes shop gift tourism museum", link_class("node", nodes(:node_with_name_current_version))
    assert_equal "node deleted", link_class("node", nodes(:node_with_name_redacted_version))
  end

  def test_link_title
    add_tags_selection(current_nodes(:node_with_name))

    assert_equal "", link_title(current_nodes(:visible_node))
    assert_equal "", link_title(current_nodes(:invisible_node))
    assert_equal "", link_title(current_nodes(:redacted_node))
    assert_equal "building=yes, shop=gift, and tourism=museum", link_title(current_nodes(:node_with_name))

    add_old_tags_selection(nodes(:node_with_name_current_version))
    add_old_tags_selection(nodes(:node_with_name_redacted_version))
    assert_equal "building=yes, shop=gift, and tourism=museum", link_title(nodes(:node_with_name_current_version))
    assert_equal "", link_title(nodes(:node_with_name_redacted_version))
  end

  def test_format_key
    html = format_key("highway")
    assert_dom_equal "<a href=\"http://wiki.openstreetmap.org/wiki/Key:highway?uselang=en\" title=\"The wiki description page for the highway tag\">highway</a>", html

    html = format_key("unknown")
    assert_dom_equal "unknown", html
  end

  def test_format_value
    html = format_value("highway", "primary")
    assert_dom_equal "<a href=\"http://wiki.openstreetmap.org/wiki/Tag:highway=primary?uselang=en\" title=\"The wiki description page for the highway=primary tag\">primary</a>", html

    html = format_value("highway", "unknown")
    assert_dom_equal "unknown", html

    html = format_value("unknown", "unknown")
    assert_dom_equal "unknown", html

    html = format_value("phone", "+1234567890")
    assert_dom_equal "<a href=\"tel:+1234567890\" title=\"Call +1234567890\">+1234567890</a>", html

    html = format_value("wikipedia", "Test")
    assert_dom_equal "<a title=\"The Test article on Wikipedia\" href=\"http://en.wikipedia.org/wiki/Test?uselang=en\">Test</a>", html

    html = format_value("wikidata", "Q42")
    assert_dom_equal "<a title=\"The Q42 item on Wikidata\" href=\"//www.wikidata.org/wiki/Q42?uselang=en\">Q42</a>", html

    html = format_value("operator:wikidata", "Q12;Q98")
    assert_dom_equal "<a title=\"The Q12 item on Wikidata\" href=\"//www.wikidata.org/wiki/Q12?uselang=en\">Q12</a>;<a title=\"The Q98 item on Wikidata\" href=\"//www.wikidata.org/wiki/Q98?uselang=en\">Q98</a>", html
  end

  def test_icon_tags
    add_tags_selection(current_nodes(:node_with_name))

    tags = icon_tags(current_nodes(:node_with_name))
    assert_equal 3, tags.count
    assert tags.include?(%w(building yes))
    assert tags.include?(%w(tourism museum))
    assert tags.include?(%w(shop gift))

    add_old_tags_selection(nodes(:node_with_name_current_version))
    add_old_tags_selection(nodes(:node_with_name_redacted_version))

    tags = icon_tags(nodes(:node_with_name_current_version))
    assert_equal 3, tags.count
    assert tags.include?(%w(building yes))
    assert tags.include?(%w(tourism museum))
    assert tags.include?(%w(shop gift))

    tags = icon_tags(nodes(:node_with_name_redacted_version))
    assert_equal 3, tags.count
    assert tags.include?(%w(building yes))
    assert tags.include?(%w(tourism museum))
    assert tags.include?(%w(shop gift))
  end

  def test_wiki_link
    link = wiki_link("key", "highway")
    assert_equal "http://wiki.openstreetmap.org/wiki/Key:highway?uselang=en", link

    link = wiki_link("tag", "highway=primary")
    assert_equal "http://wiki.openstreetmap.org/wiki/Tag:highway=primary?uselang=en", link

    I18n.locale = "de"

    link = wiki_link("key", "highway")
    assert_equal "http://wiki.openstreetmap.org/wiki/DE:Key:highway?uselang=de", link

    link = wiki_link("tag", "highway=primary")
    assert_equal "http://wiki.openstreetmap.org/wiki/DE:Tag:highway=primary?uselang=de", link

    I18n.locale = "tr"

    link = wiki_link("key", "highway")
    assert_equal "http://wiki.openstreetmap.org/wiki/Tr:Key:highway?uselang=tr", link

    link = wiki_link("tag", "highway=primary")
    assert_equal "http://wiki.openstreetmap.org/wiki/Tag:highway=primary?uselang=tr", link
  end

  def test_wikidata_links
    ### Non-prefixed wikidata-tag (only one value allowed)

    # Non-wikidata tag
    links = wikidata_links("foo", "Test")
    assert_nil links

    # No URLs allowed
    links = wikidata_links("wikidata", "http://www.wikidata.org/wiki/Q1")
    assert_nil links

    # No language-prefixes (as wikidata is multilanguage)
    links = wikidata_links("wikidata", "en:Q1")
    assert_nil links

    # Needs a leading Q
    links = wikidata_links("wikidata", "1")
    assert_nil links

    # No leading zeros allowed
    links = wikidata_links("wikidata", "Q0123")
    assert_nil links

    # A valid value
    links = wikidata_links("wikidata", "Q42")
    assert_equal 1, links.length
    assert_equal "//www.wikidata.org/wiki/Q42?uselang=en", links[0][:url]
    assert_equal "Q42", links[0][:title]

    # the language of the wikidata-page should match the current locale
    I18n.locale = "zh-CN"
    links = wikidata_links("wikidata", "Q1234")
    assert_equal 1, links.length
    assert_equal "//www.wikidata.org/wiki/Q1234?uselang=zh-CN", links[0][:url]
    assert_equal "Q1234", links[0][:title]
    I18n.locale = "en"

    ### Prefixed wikidata-tags

    # Not anything is accepted as prefix (only limited set)
    links = wikidata_links("anything:wikidata", "Q13")
    assert_nil links

    # This for example is an allowed key
    links = wikidata_links("operator:wikidata", "Q24")
    assert_equal "//www.wikidata.org/wiki/Q24?uselang=en", links[0][:url]
    assert_equal "Q24", links[0][:title]

    # Another allowed key, this time with multiple values and I18n
    I18n.locale = "dsb"
    links = wikidata_links("brand:wikidata", "Q936;Q2013;Q1568346")
    assert_equal 3, links.length
    assert_equal "//www.wikidata.org/wiki/Q936?uselang=dsb", links[0][:url]
    assert_equal "Q936", links[0][:title]
    assert_equal "//www.wikidata.org/wiki/Q2013?uselang=dsb", links[1][:url]
    assert_equal "Q2013", links[1][:title]
    assert_equal "//www.wikidata.org/wiki/Q1568346?uselang=dsb", links[2][:url]
    assert_equal "Q1568346", links[2][:title]
    I18n.locale = "en"

    # and now with whitespaces...
    links = wikidata_links("subject:wikidata", "Q6542248 ;\tQ180\n ;\rQ364\t\n\r ;\nQ4006")
    assert_equal 4, links.length
    assert_equal "//www.wikidata.org/wiki/Q6542248?uselang=en", links[0][:url]
    assert_equal "Q6542248 ", links[0][:title]
    assert_equal "//www.wikidata.org/wiki/Q180?uselang=en", links[1][:url]
    assert_equal "\tQ180\n ", links[1][:title]
    assert_equal "//www.wikidata.org/wiki/Q364?uselang=en", links[2][:url]
    assert_equal "\rQ364\t\n\r ", links[2][:title]
    assert_equal "//www.wikidata.org/wiki/Q4006?uselang=en", links[3][:url]
    assert_equal "\nQ4006", links[3][:title]
  end

  def test_wikipedia_link
    link = wikipedia_link("wikipedia", "http://en.wikipedia.org/wiki/Full%20URL")
    assert_nil link

    link = wikipedia_link("wikipedia", "https://en.wikipedia.org/wiki/Full%20URL")
    assert_nil link

    link = wikipedia_link("wikipedia", "Test")
    assert_equal "http://en.wikipedia.org/wiki/Test?uselang=en", link[:url]
    assert_equal "Test", link[:title]

    link = wikipedia_link("wikipedia", "de:Test")
    assert_equal "http://de.wikipedia.org/wiki/de:Test?uselang=en", link[:url]
    assert_equal "de:Test", link[:title]

    link = wikipedia_link("wikipedia:fr", "de:Test")
    assert_equal "http://fr.wikipedia.org/wiki/de:Test?uselang=en", link[:url]
    assert_equal "de:Test", link[:title]

    link = wikipedia_link("wikipedia", "de:Englischer Garten (München)#Japanisches Teehaus")
    assert_equal "http://de.wikipedia.org/wiki/de:Englischer Garten (München)?uselang=en#Japanisches_Teehaus", link[:url]
    assert_equal "de:Englischer Garten (München)#Japanisches Teehaus", link[:title]

    link = wikipedia_link("wikipedia", "de:Alte Brücke (Heidelberg)#Brückenaffe")
    assert_equal "http://de.wikipedia.org/wiki/de:Alte Brücke (Heidelberg)?uselang=en#Br.C3.BCckenaffe", link[:url]
    assert_equal "de:Alte Brücke (Heidelberg)#Brückenaffe", link[:title]

    link = wikipedia_link("wikipedia", "de:Liste der Baudenkmäler in Eichstätt#Brückenstraße 1, Ehemaliges Bauernhaus")
    assert_equal "http://de.wikipedia.org/wiki/de:Liste der Baudenkmäler in Eichstätt?uselang=en#Br.C3.BCckenstra.C3.9Fe_1.2C_Ehemaliges_Bauernhaus", link[:url]
    assert_equal "de:Liste der Baudenkmäler in Eichstätt#Brückenstraße 1, Ehemaliges Bauernhaus", link[:title]

    I18n.locale = "pt-BR"

    link = wikipedia_link("wikipedia", "zh-classical:Test#Section")
    assert_equal "http://zh-classical.wikipedia.org/wiki/zh-classical:Test?uselang=pt-BR#Section", link[:url]
    assert_equal "zh-classical:Test#Section", link[:title]

    link = wikipedia_link("foo", "Test")
    assert_nil link
  end

  def test_telephone_link
    link = telephone_link("foo", "Test")
    assert_nil link

    link = telephone_link("phone", "+123")
    assert_nil link

    link = telephone_link("phone", "123")
    assert_nil link

    link = telephone_link("phone", "123 abcdefg")
    assert_nil link

    link = telephone_link("phone", "+1234567890 abc")
    assert_nil link

    link = telephone_link("phone", "+1234567890; +22334455667788")
    assert_nil link

    link = telephone_link("phone", "1234567890")
    assert_nil link

    link = telephone_link("phone", "+1234567890")
    assert_equal "tel:+1234567890", link

    link = telephone_link("phone", "+1234-567-890")
    assert_equal "tel:+1234-567-890", link

    link = telephone_link("phone", "+1234/567/890")
    assert_equal "tel:+1234/567/890", link

    link = telephone_link("phone", "+1234.567.890")
    assert_equal "tel:+1234.567.890", link

    link = telephone_link("phone", "   +1234 567-890	")
    assert_equal "tel:+1234567-890", link

    link = telephone_link("phone", "+1 234-567-890")
    assert_equal "tel:+1234-567-890", link

    link = telephone_link("phone", "+1 (234) 567-890")
    assert_equal "tel:+1(234)567-890", link
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
end
