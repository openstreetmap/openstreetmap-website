# frozen_string_literal: true

require "test_helper"

class TagParserTest < ActiveSupport::TestCase
  def test_wiki_link
    link = TagParser.wiki_link("key", "highway")
    assert_equal "https://wiki.openstreetmap.org/wiki/Key:highway?uselang=en", link

    link = TagParser.wiki_link("tag", "highway=primary")
    assert_equal "https://wiki.openstreetmap.org/wiki/Tag:highway=primary?uselang=en", link

    I18n.with_locale "de" do
      link = TagParser.wiki_link("key", "highway")
      assert_equal "https://wiki.openstreetmap.org/wiki/DE:Key:highway?uselang=de", link

      link = TagParser.wiki_link("tag", "highway=primary")
      assert_equal "https://wiki.openstreetmap.org/wiki/DE:Tag:highway=primary?uselang=de", link
    end

    I18n.with_locale "tr" do
      link = TagParser.wiki_link("key", "highway")
      assert_equal "https://wiki.openstreetmap.org/wiki/Tr:Key:highway?uselang=tr", link

      link = TagParser.wiki_link("tag", "highway=primary")
      assert_equal "https://wiki.openstreetmap.org/wiki/Tag:highway=primary?uselang=tr", link
    end
  end

  def test_wikidata_links
    ### Non-prefixed wikidata-tag (only one value allowed)

    # Non-wikidata tag
    links = TagParser.wikidata_links("foo", "Test")
    assert_nil links

    # No URLs allowed
    links = TagParser.wikidata_links("wikidata", "http://www.wikidata.org/entity/Q1")
    assert_nil links

    # No language-prefixes (as wikidata is multilanguage)
    links = TagParser.wikidata_links("wikidata", "en:Q1")
    assert_nil links

    # Needs a leading Q
    links = TagParser.wikidata_links("wikidata", "1")
    assert_nil links

    # No leading zeros allowed
    links = TagParser.wikidata_links("wikidata", "Q0123")
    assert_nil links

    # A valid value
    links = TagParser.wikidata_links("wikidata", "Q42")
    assert_equal 1, links.length
    assert_equal "//www.wikidata.org/entity/Q42?uselang=en", links[0][:url]
    assert_equal "Q42", links[0][:title]

    # the language of the wikidata-page should match the current locale
    I18n.with_locale "zh-CN" do
      links = TagParser.wikidata_links("wikidata", "Q1234")
      assert_equal 1, links.length
      assert_equal "//www.wikidata.org/entity/Q1234?uselang=zh-CN", links[0][:url]
      assert_equal "Q1234", links[0][:title]
    end

    ### Prefixed wikidata-tags

    # Not anything is accepted as prefix (only limited set)
    links = TagParser.wikidata_links("anything:wikidata", "Q13")
    assert_nil links

    # This for example is an allowed key
    links = TagParser.wikidata_links("operator:wikidata", "Q24")
    assert_equal "//www.wikidata.org/entity/Q24?uselang=en", links[0][:url]
    assert_equal "Q24", links[0][:title]

    # This verified buried is working
    links = TagParser.wikidata_links("buried:wikidata", "Q24")
    assert_equal "//www.wikidata.org/entity/Q24?uselang=en", links[0][:url]
    assert_equal "Q24", links[0][:title]

    links = TagParser.wikidata_links("species:wikidata", "Q26899")
    assert_equal "//www.wikidata.org/entity/Q26899?uselang=en", links[0][:url]
    assert_equal "Q26899", links[0][:title]

    # Another allowed key, this time with multiple values and I18n
    I18n.with_locale "dsb" do
      links = TagParser.wikidata_links("brand:wikidata", "Q936;Q2013;Q1568346")
      assert_equal 3, links.length
      assert_equal "//www.wikidata.org/entity/Q936?uselang=dsb", links[0][:url]
      assert_equal "Q936", links[0][:title]
      assert_equal "//www.wikidata.org/entity/Q2013?uselang=dsb", links[1][:url]
      assert_equal "Q2013", links[1][:title]
      assert_equal "//www.wikidata.org/entity/Q1568346?uselang=dsb", links[2][:url]
      assert_equal "Q1568346", links[2][:title]
    end

    # and now with whitespaces...
    links = TagParser.wikidata_links("subject:wikidata", "Q6542248 ;\tQ180\n ;\rQ364\t\n\r ;\nQ4006")
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

  def test_wikipedia_links
    links = TagParser.wikipedia_links("wikipedia", "http://en.wikipedia.org/wiki/Full%20URL")
    assert_nil links

    links = TagParser.wikipedia_links("wikipedia", "https://en.wikipedia.org/wiki/Full%20URL")
    assert_nil links

    links = TagParser.wikipedia_links("wikipedia", "Test")
    assert_equal 1, links.length
    assert_equal "https://en.wikipedia.org/wiki/Test?uselang=en", links[0][:url]
    assert_equal "Test", links[0][:title]

    links = TagParser.wikipedia_links("wikipedia", "de:Test")
    assert_equal 1, links.length
    assert_equal "https://de.wikipedia.org/wiki/Test?uselang=en", links[0][:url]
    assert_equal "de:Test", links[0][:title]

    links = TagParser.wikipedia_links("wikipedia:fr", "Portsea")
    assert_equal 1, links.length
    assert_equal "https://fr.wikipedia.org/wiki/Portsea?uselang=en", links[0][:url]
    assert_equal "Portsea", links[0][:title]

    links = TagParser.wikipedia_links("wikipedia:fr", "de:Test")
    assert_equal 1, links.length
    assert_equal "https://de.wikipedia.org/wiki/Test?uselang=en", links[0][:url]
    assert_equal "de:Test", links[0][:title]

    links = TagParser.wikipedia_links("wikipedia", "de:Englischer Garten (München)#Japanisches Teehaus")
    assert_equal 1, links.length
    assert_equal "https://de.wikipedia.org/wiki/Englischer_Garten_%28M%C3%BCnchen%29?uselang=en#Japanisches_Teehaus", links[0][:url]
    assert_equal "de:Englischer Garten (München)#Japanisches Teehaus", links[0][:title]

    links = TagParser.wikipedia_links("wikipedia", "de:Alte Brücke (Heidelberg)#Brückenaffe")
    assert_equal 1, links.length
    assert_equal "https://de.wikipedia.org/wiki/Alte_Br%C3%BCcke_%28Heidelberg%29?uselang=en#Br%C3%BCckenaffe", links[0][:url]
    assert_equal "de:Alte Brücke (Heidelberg)#Brückenaffe", links[0][:title]

    links = TagParser.wikipedia_links("wikipedia", "de:Liste der Baudenkmäler in Eichstätt#Brückenstraße 1, Ehemaliges Bauernhaus")
    assert_equal 1, links.length
    assert_equal "https://de.wikipedia.org/wiki/Liste_der_Baudenkm%C3%A4ler_in_Eichst%C3%A4tt?uselang=en#Br%C3%BCckenstra%C3%9Fe_1%2C_Ehemaliges_Bauernhaus", links[0][:url]
    assert_equal "de:Liste der Baudenkmäler in Eichstätt#Brückenstraße 1, Ehemaliges Bauernhaus", links[0][:title]

    links = TagParser.wikipedia_links("wikipedia", "en:Are Years What? (for Marianne Moore)")
    assert_equal 1, links.length
    assert_equal "https://en.wikipedia.org/wiki/Are_Years_What%3F_%28for_Marianne_Moore%29?uselang=en", links[0][:url]
    assert_equal "en:Are Years What? (for Marianne Moore)", links[0][:title]

    I18n.with_locale "pt-BR" do
      links = TagParser.wikipedia_links("wikipedia", "zh-classical:Test#Section")
      assert_equal 1, links.length
      assert_equal "https://zh-classical.wikipedia.org/wiki/Test?uselang=pt-BR#Section", links[0][:url]
      assert_equal "zh-classical:Test#Section", links[0][:title]
    end

    links = TagParser.wikipedia_links("subject:wikipedia", "en:Catherine McAuley")
    assert_equal 1, links.length
    assert_equal "https://en.wikipedia.org/wiki/Catherine_McAuley?uselang=en", links[0][:url]
    assert_equal "en:Catherine McAuley", links[0][:title]

    links = TagParser.wikipedia_links("artist:wikipedia", "en:Pablo Picasso")
    assert_equal 1, links.length
    assert_equal "https://en.wikipedia.org/wiki/Pablo_Picasso?uselang=en", links[0][:url]
    assert_equal "en:Pablo Picasso", links[0][:title]

    links = TagParser.wikipedia_links("architect:wikipedia", "en:Frank Lloyd Wright")
    assert_equal 1, links.length
    assert_equal "https://en.wikipedia.org/wiki/Frank_Lloyd_Wright?uselang=en", links[0][:url]
    assert_equal "en:Frank Lloyd Wright", links[0][:title]

    links = TagParser.wikipedia_links("buried:wikipedia", "en:Stephen Hawking")
    assert_equal 1, links.length
    assert_equal "https://en.wikipedia.org/wiki/Stephen_Hawking?uselang=en", links[0][:url]
    assert_equal "en:Stephen Hawking", links[0][:title]

    links = TagParser.wikipedia_links("foo", "Test")
    assert_nil links

    # Multiple values separated by ;
    links = TagParser.wikipedia_links("wikipedia", "Test;Hello")
    assert_equal 2, links.length
    assert_equal "https://en.wikipedia.org/wiki/Test?uselang=en", links[0][:url]
    assert_equal "Test", links[0][:title]
    assert_equal "https://en.wikipedia.org/wiki/Hello?uselang=en", links[1][:url]
    assert_equal "Hello", links[1][:title]

    links = TagParser.wikipedia_links("wikipedia", "de:Berlin;en:London;fr:Paris")
    assert_equal 3, links.length
    assert_equal "https://de.wikipedia.org/wiki/Berlin?uselang=en", links[0][:url]
    assert_equal "de:Berlin", links[0][:title]
    assert_equal "https://en.wikipedia.org/wiki/London?uselang=en", links[1][:url]
    assert_equal "en:London", links[1][:title]
    assert_equal "https://fr.wikipedia.org/wiki/Paris?uselang=en", links[2][:url]
    assert_equal "fr:Paris", links[2][:title]
  end

  def test_wikimedia_commons_link
    link = TagParser.wikimedia_commons_link("wikimedia_commons", "http://commons.wikimedia.org/wiki/File:Full%20URL.jpg")
    assert_nil link

    link = TagParser.wikimedia_commons_link("wikimedia_commons", "https://commons.wikimedia.org/wiki/File:Full%20URL.jpg")
    assert_nil link

    link = TagParser.wikimedia_commons_link("wikimedia_commons", "Test.jpg")
    assert_nil link

    link = TagParser.wikimedia_commons_link("wikimedia_commons", "File:Test.jpg")
    assert_equal "//commons.wikimedia.org/wiki/File:Test.jpg?uselang=en", link[:url]
    assert_equal "File:Test.jpg", link[:title]

    link = TagParser.wikimedia_commons_link("wikimedia_commons", "Category:Test_Category")
    assert_equal "//commons.wikimedia.org/wiki/Category:Test_Category?uselang=en", link[:url]
    assert_equal "Category:Test_Category", link[:title]

    link = TagParser.wikimedia_commons_link("wikimedia_commons", "Category:What If? (Bonn)")
    assert_equal "//commons.wikimedia.org/wiki/Category:What%20If%3F%20%28Bonn%29?uselang=en", link[:url]
    assert_equal "Category:What If? (Bonn)", link[:title]

    link = TagParser.wikimedia_commons_link("wikimedia_commons", "File:Corsica-vizzavona-abri-southwell.jpg#mediaviewer/File:Corsica-vizzavona-abri-southwell.jpg")
    assert_equal "//commons.wikimedia.org/wiki/File:Corsica-vizzavona-abri-southwell.jpg?uselang=en", link[:url]
    assert_equal "File:Corsica-vizzavona-abri-southwell.jpg#mediaviewer/File:Corsica-vizzavona-abri-southwell.jpg", link[:title]

    I18n.with_locale "pt-BR" do
      link = TagParser.wikimedia_commons_link("wikimedia_commons", "File:Test.jpg")
      assert_equal "//commons.wikimedia.org/wiki/File:Test.jpg?uselang=pt-BR", link[:url]
      assert_equal "File:Test.jpg", link[:title]
    end

    link = TagParser.wikimedia_commons_link("foo", "Test")
    assert_nil link
  end

  def test_email_link
    email = TagParser.email_link("foo", "Test")
    assert_nil email

    email = TagParser.email_link("email", "123")
    assert_nil email

    email = TagParser.email_link("email", "Abc.example.com")
    assert_nil email

    email = TagParser.email_link("email", "a@b@c.com")
    assert_nil email

    email = TagParser.email_link("email", "just\"not\"right@example.com")
    assert_nil email

    email = TagParser.email_link("email", "123 abcdefg@space.com")
    assert_nil email

    email = TagParser.email_link("email", "test@ abc")
    assert_nil email

    email = TagParser.email_link("email", "using;semicolon@test.com")
    assert_nil email

    email = TagParser.email_link("email", "x@example.com")
    assert_equal "x@example.com", email

    email = TagParser.email_link("email", "other.email-with-hyphen@example.com")
    assert_equal "other.email-with-hyphen@example.com", email

    email = TagParser.email_link("email", "user.name+tag+sorting@example.com")
    assert_equal "user.name+tag+sorting@example.com", email

    email = TagParser.email_link("email", "dash-in@both-parts.com")
    assert_equal "dash-in@both-parts.com", email

    email = TagParser.email_link("email", "example@s.example")
    assert_equal "example@s.example", email

    # Strips whitespace at ends
    email = TagParser.email_link("email", " test@email.com ")
    assert_equal "test@email.com", email

    email = TagParser.email_link("contact:email", "example@example.com")
    assert_equal "example@example.com", email

    email = TagParser.email_link("maxweight:conditional", "none@agricultural")
    assert_nil email
  end

  def test_telephone_links
    links = TagParser.telephone_links("foo", "Test")
    assert_nil links

    links = TagParser.telephone_links("phone", "+123")
    assert_nil links

    links = TagParser.telephone_links("phone", "123")
    assert_nil links

    links = TagParser.telephone_links("phone", "123 abcdefg")
    assert_nil links

    links = TagParser.telephone_links("phone", "+1234567890 abc")
    assert_nil links

    # If multiple numbers are listed, all must be valid
    links = TagParser.telephone_links("phone", "+1234567890; +223")
    assert_nil links

    links = TagParser.telephone_links("phone", "1234567890")
    assert_nil links

    links = TagParser.telephone_links("phone", "+1234567890")
    assert_equal 1, links.length
    assert_equal "+1234567890", links[0][:phone_number]
    assert_equal "tel:+1234567890", links[0][:url]

    links = TagParser.telephone_links("phone", "+1234-567-890")
    assert_equal 1, links.length
    assert_equal "+1234-567-890", links[0][:phone_number]
    assert_equal "tel:+1234-567-890", links[0][:url]

    links = TagParser.telephone_links("phone", "+1234/567/890")
    assert_equal 1, links.length
    assert_equal "+1234/567/890", links[0][:phone_number]
    assert_equal "tel:+1234/567/890", links[0][:url]

    links = TagParser.telephone_links("phone", "+1234.567.890")
    assert_equal 1, links.length
    assert_equal "+1234.567.890", links[0][:phone_number]
    assert_equal "tel:+1234.567.890", links[0][:url]

    links = TagParser.telephone_links("phone", "   +1234 567-890	")
    assert_equal 1, links.length
    assert_equal "+1234 567-890", links[0][:phone_number]
    assert_equal "tel:+1234567-890", links[0][:url]

    links = TagParser.telephone_links("phone", "+1 234-567-890")
    assert_equal 1, links.length
    assert_equal "+1 234-567-890", links[0][:phone_number]
    assert_equal "tel:+1234-567-890", links[0][:url]

    links = TagParser.telephone_links("phone", "+1 (234) 567-890")
    assert_equal 1, links.length
    assert_equal "+1 (234) 567-890", links[0][:phone_number]
    assert_equal "tel:+1(234)567-890", links[0][:url]

    # Multiple valid phone numbers separated by ;
    links = TagParser.telephone_links("phone", "+1234567890; +22334455667788")
    assert_equal 2, links.length
    assert_equal "+1234567890", links[0][:phone_number]
    assert_equal "tel:+1234567890", links[0][:url]
    assert_equal "+22334455667788", links[1][:phone_number]
    assert_equal "tel:+22334455667788", links[1][:url]

    links = TagParser.telephone_links("phone", "+1 (234) 567-890 ;  +22(33)4455.66.7788 ")
    assert_equal 2, links.length
    assert_equal "+1 (234) 567-890", links[0][:phone_number]
    assert_equal "tel:+1(234)567-890", links[0][:url]
    assert_equal "+22(33)4455.66.7788", links[1][:phone_number]
    assert_equal "tel:+22(33)4455.66.7788", links[1][:url]
  end

  def test_colour_preview
    # basic positive tests
    colour = TagParser.colour_preview("colour", "red")
    assert_equal "red", colour

    colour = TagParser.colour_preview("colour", "Red")
    assert_equal "Red", colour

    colour = TagParser.colour_preview("colour", "darkRed")
    assert_equal "darkRed", colour

    colour = TagParser.colour_preview("colour", "#f00")
    assert_equal "#f00", colour

    colour = TagParser.colour_preview("colour", "#fF0000")
    assert_equal "#fF0000", colour

    # other tag variants:
    colour = TagParser.colour_preview("building:colour", "#f00")
    assert_equal "#f00", colour

    colour = TagParser.colour_preview("ref:colour", "#f00")
    assert_equal "#f00", colour

    colour = TagParser.colour_preview("int_ref:colour", "green")
    assert_equal "green", colour

    colour = TagParser.colour_preview("roof:colour", "#f00")
    assert_equal "#f00", colour

    colour = TagParser.colour_preview("seamark:beacon_lateral:colour", "#f00")
    assert_equal "#f00", colour

    # negative tests:
    colour = TagParser.colour_preview("colour", "")
    assert_nil colour

    colour = TagParser.colour_preview("colour", "   ")
    assert_nil colour

    colour = TagParser.colour_preview("colour", nil)
    assert_nil colour

    # ignore US spelling variant
    colour = TagParser.colour_preview("color", "red")
    assert_nil colour

    # irrelevant tag names
    colour = TagParser.colour_preview("building", "red")
    assert_nil colour

    colour = TagParser.colour_preview("ref:colour_no", "red")
    assert_nil colour

    colour = TagParser.colour_preview("ref:colour-bg", "red")
    assert_nil colour

    colour = TagParser.colour_preview("int_ref", "red")
    assert_nil colour

    # invalid hex codes
    colour = TagParser.colour_preview("colour", "#")
    assert_nil colour

    colour = TagParser.colour_preview("colour", "#ff")
    assert_nil colour

    colour = TagParser.colour_preview("colour", "#ffff")
    assert_nil colour

    colour = TagParser.colour_preview("colour", "#fffffff")
    assert_nil colour

    colour = TagParser.colour_preview("colour", "#ggg")
    assert_nil colour

    colour = TagParser.colour_preview("colour", "#ff 00 00")
    assert_nil colour

    # invalid w3c color names:
    colour = TagParser.colour_preview("colour", "r")
    assert_nil colour

    colour = TagParser.colour_preview("colour", "ffffff")
    assert_nil colour

    colour = TagParser.colour_preview("colour", "f00")
    assert_nil colour

    colour = TagParser.colour_preview("colour", "xxxred")
    assert_nil colour

    colour = TagParser.colour_preview("colour", "dark red")
    assert_nil colour

    colour = TagParser.colour_preview("colour", "dark_red")
    assert_nil colour

    colour = TagParser.colour_preview("colour", "ADarkDummyLongColourNameWithAPurpleUndertone")
    assert_nil colour
  end
end
