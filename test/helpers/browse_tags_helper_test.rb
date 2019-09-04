require "test_helper"

class BrowseTagsHelperTest < ActionView::TestCase
  include ERB::Util
  include ApplicationHelper

  def setup
    I18n.locale = "en"
  end

  def teardown
    I18n.locale = "en"
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

    html = format_value("phone", "+1234567890")
    assert_dom_equal "<a href=\"tel:+1234567890\" title=\"Call +1234567890\">+1234567890</a>", html

    html = format_value("phone", "+1 (234) 567-890 ;  +22334455")
    assert_dom_equal "<a href=\"tel:+1(234)567-890\" title=\"Call +1 (234) 567-890\">+1 (234) 567-890</a>; <a href=\"tel:+22334455\" title=\"Call +22334455\">+22334455</a>", html

    html = format_value("wikipedia", "Test")
    assert_dom_equal "<a title=\"The Test article on Wikipedia\" href=\"https://en.wikipedia.org/wiki/Test?uselang=en\">Test</a>", html

    html = format_value("wikidata", "Q42")
    assert_dom_equal "<a title=\"The Q42 item on Wikidata\" href=\"//www.wikidata.org/entity/Q42?uselang=en\">Q42</a>", html

    html = format_value("operator:wikidata", "Q12;Q98")
    assert_dom_equal "<a title=\"The Q12 item on Wikidata\" href=\"//www.wikidata.org/entity/Q12?uselang=en\">Q12</a>;<a title=\"The Q98 item on Wikidata\" href=\"//www.wikidata.org/entity/Q98?uselang=en\">Q98</a>", html

    html = format_value("name:etymology:wikidata", "Q123")
    assert_dom_equal "<a title=\"The Q123 item on Wikidata\" href=\"//www.wikidata.org/entity/Q123?uselang=en\">Q123</a>", html

    html = format_value("colour", "#f00")
    assert_dom_equal %(<span class="colour-preview-box" data-colour="#f00" title="Colour #f00 preview"></span>#f00), html
  end

  def test_wiki_link
    link = wiki_link("key", "highway")
    assert_equal "https://wiki.openstreetmap.org/wiki/Key:highway?uselang=en", link

    link = wiki_link("tag", "highway=primary")
    assert_equal "https://wiki.openstreetmap.org/wiki/Tag:highway=primary?uselang=en", link

    I18n.locale = "de"

    link = wiki_link("key", "highway")
    assert_equal "https://wiki.openstreetmap.org/wiki/DE:Key:highway?uselang=de", link

    link = wiki_link("tag", "highway=primary")
    assert_equal "https://wiki.openstreetmap.org/wiki/DE:Tag:highway=primary?uselang=de", link

    I18n.locale = "tr"

    link = wiki_link("key", "highway")
    assert_equal "https://wiki.openstreetmap.org/wiki/Tr:Key:highway?uselang=tr", link

    link = wiki_link("tag", "highway=primary")
    assert_equal "https://wiki.openstreetmap.org/wiki/Tag:highway=primary?uselang=tr", link
  end

  def test_wikidata_links
    ### Non-prefixed wikidata-tag (only one value allowed)

    # Non-wikidata tag
    links = wikidata_links("foo", "Test")
    assert_nil links

    # No URLs allowed
    links = wikidata_links("wikidata", "http://www.wikidata.org/entity/Q1")
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
    assert_equal "//www.wikidata.org/entity/Q42?uselang=en", links[0][:url]
    assert_equal "Q42", links[0][:title]

    # the language of the wikidata-page should match the current locale
    I18n.locale = "zh-CN"
    links = wikidata_links("wikidata", "Q1234")
    assert_equal 1, links.length
    assert_equal "//www.wikidata.org/entity/Q1234?uselang=zh-CN", links[0][:url]
    assert_equal "Q1234", links[0][:title]
    I18n.locale = "en"

    ### Prefixed wikidata-tags

    # Not anything is accepted as prefix (only limited set)
    links = wikidata_links("anything:wikidata", "Q13")
    assert_nil links

    # This for example is an allowed key
    links = wikidata_links("operator:wikidata", "Q24")
    assert_equal "//www.wikidata.org/entity/Q24?uselang=en", links[0][:url]
    assert_equal "Q24", links[0][:title]

    # Another allowed key, this time with multiple values and I18n
    I18n.locale = "dsb"
    links = wikidata_links("brand:wikidata", "Q936;Q2013;Q1568346")
    assert_equal 3, links.length
    assert_equal "//www.wikidata.org/entity/Q936?uselang=dsb", links[0][:url]
    assert_equal "Q936", links[0][:title]
    assert_equal "//www.wikidata.org/entity/Q2013?uselang=dsb", links[1][:url]
    assert_equal "Q2013", links[1][:title]
    assert_equal "//www.wikidata.org/entity/Q1568346?uselang=dsb", links[2][:url]
    assert_equal "Q1568346", links[2][:title]
    I18n.locale = "en"

    # and now with whitespaces...
    links = wikidata_links("subject:wikidata", "Q6542248 ;\tQ180\n ;\rQ364\t\n\r ;\nQ4006")
    assert_equal 4, links.length
    assert_equal "//www.wikidata.org/entity/Q6542248?uselang=en", links[0][:url]
    assert_equal "Q6542248 ", links[0][:title]
    assert_equal "//www.wikidata.org/entity/Q180?uselang=en", links[1][:url]
    assert_equal "\tQ180\n ", links[1][:title]
    assert_equal "//www.wikidata.org/entity/Q364?uselang=en", links[2][:url]
    assert_equal "\rQ364\t\n\r ", links[2][:title]
    assert_equal "//www.wikidata.org/entity/Q4006?uselang=en", links[3][:url]
    assert_equal "\nQ4006", links[3][:title]
  end

  def test_wikipedia_link
    link = wikipedia_link("wikipedia", "http://en.wikipedia.org/wiki/Full%20URL")
    assert_nil link

    link = wikipedia_link("wikipedia", "https://en.wikipedia.org/wiki/Full%20URL")
    assert_nil link

    link = wikipedia_link("wikipedia", "Test")
    assert_equal "https://en.wikipedia.org/wiki/Test?uselang=en", link[:url]
    assert_equal "Test", link[:title]

    link = wikipedia_link("wikipedia", "de:Test")
    assert_equal "https://de.wikipedia.org/wiki/de:Test?uselang=en", link[:url]
    assert_equal "de:Test", link[:title]

    link = wikipedia_link("wikipedia:fr", "de:Test")
    assert_equal "https://fr.wikipedia.org/wiki/de:Test?uselang=en", link[:url]
    assert_equal "de:Test", link[:title]

    link = wikipedia_link("wikipedia", "de:Englischer Garten (München)#Japanisches Teehaus")
    assert_equal "https://de.wikipedia.org/wiki/de:Englischer Garten (München)?uselang=en#Japanisches_Teehaus", link[:url]
    assert_equal "de:Englischer Garten (München)#Japanisches Teehaus", link[:title]

    link = wikipedia_link("wikipedia", "de:Alte Brücke (Heidelberg)#Brückenaffe")
    assert_equal "https://de.wikipedia.org/wiki/de:Alte Brücke (Heidelberg)?uselang=en#Br.C3.BCckenaffe", link[:url]
    assert_equal "de:Alte Brücke (Heidelberg)#Brückenaffe", link[:title]

    link = wikipedia_link("wikipedia", "de:Liste der Baudenkmäler in Eichstätt#Brückenstraße 1, Ehemaliges Bauernhaus")
    assert_equal "https://de.wikipedia.org/wiki/de:Liste der Baudenkmäler in Eichstätt?uselang=en#Br.C3.BCckenstra.C3.9Fe_1.2C_Ehemaliges_Bauernhaus", link[:url]
    assert_equal "de:Liste der Baudenkmäler in Eichstätt#Brückenstraße 1, Ehemaliges Bauernhaus", link[:title]

    I18n.locale = "pt-BR"

    link = wikipedia_link("wikipedia", "zh-classical:Test#Section")
    assert_equal "https://zh-classical.wikipedia.org/wiki/zh-classical:Test?uselang=pt-BR#Section", link[:url]
    assert_equal "zh-classical:Test#Section", link[:title]

    link = wikipedia_link("foo", "Test")
    assert_nil link
  end

  def test_telephone_links
    links = telephone_links("foo", "Test")
    assert_nil links

    links = telephone_links("phone", "+123")
    assert_nil links

    links = telephone_links("phone", "123")
    assert_nil links

    links = telephone_links("phone", "123 abcdefg")
    assert_nil links

    links = telephone_links("phone", "+1234567890 abc")
    assert_nil links

    # If multiple numbers are listed, all must be valid
    links = telephone_links("phone", "+1234567890; +223")
    assert_nil links

    links = telephone_links("phone", "1234567890")
    assert_nil links

    links = telephone_links("phone", "+1234567890")
    assert_equal 1, links.length
    assert_equal "+1234567890", links[0][:phone_number]
    assert_equal "tel:+1234567890", links[0][:url]

    links = telephone_links("phone", "+1234-567-890")
    assert_equal 1, links.length
    assert_equal "+1234-567-890", links[0][:phone_number]
    assert_equal "tel:+1234-567-890", links[0][:url]

    links = telephone_links("phone", "+1234/567/890")
    assert_equal 1, links.length
    assert_equal "+1234/567/890", links[0][:phone_number]
    assert_equal "tel:+1234/567/890", links[0][:url]

    links = telephone_links("phone", "+1234.567.890")
    assert_equal 1, links.length
    assert_equal "+1234.567.890", links[0][:phone_number]
    assert_equal "tel:+1234.567.890", links[0][:url]

    links = telephone_links("phone", "   +1234 567-890	")
    assert_equal 1, links.length
    assert_equal "+1234 567-890", links[0][:phone_number]
    assert_equal "tel:+1234567-890", links[0][:url]

    links = telephone_links("phone", "+1 234-567-890")
    assert_equal 1, links.length
    assert_equal "+1 234-567-890", links[0][:phone_number]
    assert_equal "tel:+1234-567-890", links[0][:url]

    links = telephone_links("phone", "+1 (234) 567-890")
    assert_equal 1, links.length
    assert_equal "+1 (234) 567-890", links[0][:phone_number]
    assert_equal "tel:+1(234)567-890", links[0][:url]

    # Multiple valid phone numbers separated by ;
    links = telephone_links("phone", "+1234567890; +22334455667788")
    assert_equal 2, links.length
    assert_equal "+1234567890", links[0][:phone_number]
    assert_equal "tel:+1234567890", links[0][:url]
    assert_equal "+22334455667788", links[1][:phone_number]
    assert_equal "tel:+22334455667788", links[1][:url]

    links = telephone_links("phone", "+1 (234) 567-890 ;  +22(33)4455.66.7788 ")
    assert_equal 2, links.length
    assert_equal "+1 (234) 567-890", links[0][:phone_number]
    assert_equal "tel:+1(234)567-890", links[0][:url]
    assert_equal "+22(33)4455.66.7788", links[1][:phone_number]
    assert_equal "tel:+22(33)4455.66.7788", links[1][:url]
  end

  def test_colour_preview
    # basic positive tests
    colour = colour_preview("colour", "red")
    assert_equal "red", colour

    colour = colour_preview("colour", "Red")
    assert_equal "Red", colour

    colour = colour_preview("colour", "darkRed")
    assert_equal "darkRed", colour

    colour = colour_preview("colour", "#f00")
    assert_equal "#f00", colour

    colour = colour_preview("colour", "#fF0000")
    assert_equal "#fF0000", colour

    # other tag variants:
    colour = colour_preview("building:colour", "#f00")
    assert_equal "#f00", colour

    colour = colour_preview("ref:colour", "#f00")
    assert_equal "#f00", colour

    colour = colour_preview("int_ref:colour", "green")
    assert_equal "green", colour

    colour = colour_preview("roof:colour", "#f00")
    assert_equal "#f00", colour

    colour = colour_preview("seamark:beacon_lateral:colour", "#f00")
    assert_equal "#f00", colour

    # negative tests:
    colour = colour_preview("colour", "")
    assert_nil colour

    colour = colour_preview("colour", "   ")
    assert_nil colour

    colour = colour_preview("colour", nil)
    assert_nil colour

    # ignore US spelling variant
    colour = colour_preview("color", "red")
    assert_nil colour

    # irrelevant tag names
    colour = colour_preview("building", "red")
    assert_nil colour

    colour = colour_preview("ref:colour_no", "red")
    assert_nil colour

    colour = colour_preview("ref:colour-bg", "red")
    assert_nil colour

    colour = colour_preview("int_ref", "red")
    assert_nil colour

    # invalid hex codes
    colour = colour_preview("colour", "#")
    assert_nil colour

    colour = colour_preview("colour", "#ff")
    assert_nil colour

    colour = colour_preview("colour", "#ffff")
    assert_nil colour

    colour = colour_preview("colour", "#fffffff")
    assert_nil colour

    colour = colour_preview("colour", "#ggg")
    assert_nil colour

    colour = colour_preview("colour", "#ff 00 00")
    assert_nil colour

    # invalid w3c color names:
    colour = colour_preview("colour", "r")
    assert_nil colour

    colour = colour_preview("colour", "ffffff")
    assert_nil colour

    colour = colour_preview("colour", "f00")
    assert_nil colour

    colour = colour_preview("colour", "xxxred")
    assert_nil colour

    colour = colour_preview("colour", "dark red")
    assert_nil colour

    colour = colour_preview("colour", "dark_red")
    assert_nil colour

    colour = colour_preview("colour", "ADarkDummyLongColourNameWithAPurpleUndertone")
    assert_nil colour
  end
end
