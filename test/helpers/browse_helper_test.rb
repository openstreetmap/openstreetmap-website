# -*- coding: utf-8 -*-

require 'test_helper'

class BrowseHelperTest < ActionView::TestCase
  include ERB::Util
  include ApplicationHelper

  api_fixtures

  def setup
    I18n.locale = "en"
  end

  def test_printable_name
    assert_equal "17", printable_name(current_nodes(:redacted_node))
    assert_equal "<bdi>Test Node</bdi> (<bdi>18</bdi>)", printable_name(current_nodes(:node_with_name))
    assert_equal "<bdi>Test Node</bdi> (<bdi>18</bdi>)", printable_name(nodes(:node_with_name_current_version))
    assert_equal "18", printable_name(nodes(:node_with_name_redacted_version))
    assert_equal "<bdi>Test Node</bdi> (<bdi>18, v2</bdi>)", printable_name(nodes(:node_with_name_current_version), true)
    assert_equal "18, v1", printable_name(nodes(:node_with_name_redacted_version), true)

    I18n.locale = "ru"

    assert_equal "17", printable_name(current_nodes(:redacted_node))
    assert_equal "<bdi>проверки узла</bdi> (<bdi>18</bdi>)", printable_name(current_nodes(:node_with_name))
    assert_equal "<bdi>проверки узла</bdi> (<bdi>18</bdi>)", printable_name(nodes(:node_with_name_current_version))
    assert_equal "18", printable_name(nodes(:node_with_name_redacted_version))
    assert_equal "<bdi>проверки узла</bdi> (<bdi>18, v2</bdi>)", printable_name(nodes(:node_with_name_current_version), true)
    assert_equal "18, v1", printable_name(nodes(:node_with_name_redacted_version), true)

    I18n.locale = "de"

    assert_equal "17", printable_name(current_nodes(:redacted_node))
    assert_equal "<bdi>Test Node</bdi> (<bdi>18</bdi>)", printable_name(current_nodes(:node_with_name))
    assert_equal "<bdi>Test Node</bdi> (<bdi>18</bdi>)", printable_name(nodes(:node_with_name_current_version))
    assert_equal "18", printable_name(nodes(:node_with_name_redacted_version))
    assert_equal "<bdi>Test Node</bdi> (<bdi>18, v2</bdi>)", printable_name(nodes(:node_with_name_current_version), true)
    assert_equal "18, v1", printable_name(nodes(:node_with_name_redacted_version), true)
  end

  def test_link_class
    assert_equal "node", link_class("node", current_nodes(:visible_node))
    assert_equal "node deleted", link_class("node", current_nodes(:invisible_node))
    assert_equal "node deleted", link_class("node", current_nodes(:redacted_node))
    assert_equal "node building yes shop gift tourism museum", link_class("node", current_nodes(:node_with_name))
    assert_equal "node building yes shop gift tourism museum", link_class("node", nodes(:node_with_name_current_version))
    assert_equal "node deleted", link_class("node", nodes(:node_with_name_redacted_version))
  end

  def test_link_title
    assert_equal "", link_title(current_nodes(:visible_node))
    assert_equal "", link_title(current_nodes(:invisible_node))
    assert_equal "", link_title(current_nodes(:redacted_node))
    assert_equal "building=yes, shop=gift, and tourism=museum", link_title(current_nodes(:node_with_name))
    assert_equal "building=yes, shop=gift, and tourism=museum", link_title(nodes(:node_with_name_current_version))
    assert_equal "", link_title(nodes(:node_with_name_redacted_version))
  end

  def test_format_key
    html = format_key("highway")
    assert_equal "<a href=\"http://wiki.openstreetmap.org/wiki/Key:highway?uselang=en\" title=\"The wiki description page for the highway tag\">highway</a>", html

    html = format_key("unknown")
    assert_equal "unknown", html
  end

  def test_format_value
    html = format_value("highway", "primary")
    assert_equal "<a href=\"http://wiki.openstreetmap.org/wiki/Tag:highway=primary?uselang=en\" title=\"The wiki description page for the highway=primary tag\">primary</a>", html

    html = format_value("highway", "unknown")
    assert_equal "unknown", html

    html = format_value("unknown", "unknown")
    assert_equal "unknown", html
  end

  def test_icon_tags
    tags = icon_tags(current_nodes(:node_with_name))
    assert_equal 3, tags.count
    assert tags.include?(["building", "yes"])
    assert tags.include?(["tourism", "museum"])
    assert tags.include?(["shop", "gift"])

    tags = icon_tags(nodes(:node_with_name_current_version))
    assert_equal 3, tags.count
    assert tags.include?(["building", "yes"])
    assert tags.include?(["tourism", "museum"])
    assert tags.include?(["shop", "gift"])

    tags = icon_tags(nodes(:node_with_name_redacted_version))
    assert_equal 3, tags.count
    assert tags.include?(["building", "yes"])
    assert tags.include?(["tourism", "museum"])
    assert tags.include?(["shop", "gift"])
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

    I18n.locale = "pt-BR"

    link = wikipedia_link("wikipedia", "zh-classical:Test#Section")
    assert_equal "http://zh-classical.wikipedia.org/wiki/zh-classical:Test?uselang=pt-BR#Section", link[:url]
    assert_equal "zh-classical:Test#Section", link[:title]

    link = wikipedia_link("foo", "Test")
    assert_nil link
  end
end
