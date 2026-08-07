# frozen_string_literal: true

require "test_helper"

class BrowseTagsHelperTest < ActionView::TestCase
  include ERB::Util
  include ApplicationHelper

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

  def test_email_link
    email = email_link("foo", "Test")
    assert_nil email

    email = email_link("email", "123")
    assert_nil email

    email = email_link("email", "Abc.example.com")
    assert_nil email

    email = email_link("email", "a@b@c.com")
    assert_nil email

    email = email_link("email", "just\"not\"right@example.com")
    assert_nil email

    email = email_link("email", "123 abcdefg@space.com")
    assert_nil email

    email = email_link("email", "test@ abc")
    assert_nil email

    email = email_link("email", "using;semicolon@test.com")
    assert_nil email

    email = email_link("email", "x@example.com")
    assert_equal "x@example.com", email

    email = email_link("email", "other.email-with-hyphen@example.com")
    assert_equal "other.email-with-hyphen@example.com", email

    email = email_link("email", "user.name+tag+sorting@example.com")
    assert_equal "user.name+tag+sorting@example.com", email

    email = email_link("email", "dash-in@both-parts.com")
    assert_equal "dash-in@both-parts.com", email

    email = email_link("email", "example@s.example")
    assert_equal "example@s.example", email

    # Strips whitespace at ends
    email = email_link("email", " test@email.com ")
    assert_equal "test@email.com", email

    email = email_link("contact:email", "example@example.com")
    assert_equal "example@example.com", email

    email = email_link("maxweight:conditional", "none@agricultural")
    assert_nil email
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
