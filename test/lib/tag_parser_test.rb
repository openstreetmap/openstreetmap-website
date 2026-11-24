# frozen_string_literal: true

require "test_helper"

class TagParserTest < ActiveSupport::TestCase
  def test_wiki_link
    links = TagParser.wiki_link("key", "highway")
    assert_equal [{ :text => "highway", :url => "https://wiki.openstreetmap.org/wiki/Key:highway?uselang=en", :type => :"wiki_link.key", :key => "highway" }], links

    links = TagParser.wiki_link("tag", "highway", "primary")
    assert_equal [{ :text => "primary", :url => "https://wiki.openstreetmap.org/wiki/Tag:highway=primary?uselang=en", :type => :"wiki_link.tag", :key => "highway", :value => "primary" }], links

    I18n.with_locale "de" do
      links = TagParser.wiki_link("key", "highway")
      assert_equal [{ :text => "highway", :url => "https://wiki.openstreetmap.org/wiki/DE:Key:highway?uselang=de", :type => :"wiki_link.key", :key => "highway" }], links

      links = TagParser.wiki_link("tag", "highway", "primary")
      assert_equal [{ :text => "primary", :url => "https://wiki.openstreetmap.org/wiki/DE:Tag:highway=primary?uselang=de", :type => :"wiki_link.tag", :key => "highway", :value => "primary" }], links
    end

    I18n.with_locale "tr" do
      links = TagParser.wiki_link("key", "highway")
      assert_equal [{ :text => "highway", :url => "https://wiki.openstreetmap.org/wiki/Tr:Key:highway?uselang=tr", :type => :"wiki_link.key", :key => "highway" }], links

      links = TagParser.wiki_link("tag", "highway", "path")
      assert_equal [{ :text => "path", :url => "https://wiki.openstreetmap.org/wiki/Tag:highway=path?uselang=tr", :type => :"wiki_link.tag", :key => "highway", :value => "path" }], links
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
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :wikidata_preview, :qids => ["Q42"], :count => 1 }, links[0])
    assert_equal({ :text => "Q42", :url => "https://www.wikidata.org/entity/Q42?uselang=en", :type => :wikidata_link, :page => "Q42" }, links[1])

    # the language of the wikidata-page should match the current locale
    I18n.with_locale "zh-CN" do
      links = TagParser.wikidata_links("wikidata", "Q1234")
      assert_equal 2, links.length
      assert_equal({ :type => :html, :widget => :wikidata_preview, :qids => ["Q1234"], :count => 1 }, links[0])
      assert_equal({ :text => "Q1234", :url => "https://www.wikidata.org/entity/Q1234?uselang=zh-CN", :type => :wikidata_link, :page => "Q1234" }, links[1])
    end

    ### Prefixed wikidata-tags

    # examples for secondary wikidata keys
    links = TagParser.wikidata_links("operator:wikidata", "Q24")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :wikidata_preview, :qids => ["Q24"], :count => 1 }, links[0])
    assert_equal({ :text => "Q24", :url => "https://www.wikidata.org/entity/Q24?uselang=en", :type => :wikidata_link, :page => "Q24" }, links[1])

    links = TagParser.wikidata_links("buried:wikidata", "Q24")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :wikidata_preview, :qids => ["Q24"], :count => 1 }, links[0])
    assert_equal({ :text => "Q24", :url => "https://www.wikidata.org/entity/Q24?uselang=en", :type => :wikidata_link, :page => "Q24" }, links[1])

    links = TagParser.wikidata_links("species:wikidata", "Q26899")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :wikidata_preview, :qids => ["Q26899"], :count => 1 }, links[0])
    assert_equal({ :text => "Q26899", :url => "https://www.wikidata.org/entity/Q26899?uselang=en", :type => :wikidata_link, :page => "Q26899" }, links[1])

    links = TagParser.wikidata_links("name:etymology:wikidata", "Q121745508")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :wikidata_preview, :qids => ["Q121745508"], :count => 1 }, links[0])
    assert_equal({ :text => "Q121745508", :url => "https://www.wikidata.org/entity/Q121745508?uselang=en", :type => :wikidata_link, :page => "Q121745508" }, links[1])

    # Another one with multiple values and I18n
    I18n.with_locale "dsb" do
      links = TagParser.wikidata_links("brand:wikidata", "Q936;Q2013;Q1568346")
      assert_equal 4, links.length
      assert_equal({ :type => :html, :widget => :wikidata_preview, :qids => %w[Q936 Q2013 Q1568346], :count => 3 }, links[0])
      assert_equal({ :text => "Q936", :url => "https://www.wikidata.org/entity/Q936?uselang=dsb", :type => :wikidata_link, :page => "Q936" }, links[1])
      assert_equal({ :text => "Q2013", :url => "https://www.wikidata.org/entity/Q2013?uselang=dsb", :type => :wikidata_link, :page => "Q2013" }, links[2])
      assert_equal({ :text => "Q1568346", :url => "https://www.wikidata.org/entity/Q1568346?uselang=dsb", :type => :wikidata_link, :page => "Q1568346" }, links[3])
    end

    # and now with whitespaces...
    links = TagParser.wikidata_links("subject:wikidata", "Q6542248 ;\tQ180\n ;\rQ364\t\n\r ;\nQ4006")
    assert_equal 5, links.length
    assert_equal({ :type => :html, :widget => :wikidata_preview, :qids => %w[Q6542248 Q180 Q364 Q4006], :count => 4 }, links[0])
    assert_equal({ :text => "Q6542248 ", :url => "https://www.wikidata.org/entity/Q6542248?uselang=en", :type => :wikidata_link, :page => "Q6542248" }, links[1])
    assert_equal({ :text => "\tQ180\n ", :url => "https://www.wikidata.org/entity/Q180?uselang=en", :type => :wikidata_link, :page => "Q180" }, links[2])
    assert_equal({ :text => "\rQ364\t\n\r ", :url => "https://www.wikidata.org/entity/Q364?uselang=en", :type => :wikidata_link, :page => "Q364" }, links[3])
    assert_equal({ :text => "\nQ4006", :url => "https://www.wikidata.org/entity/Q4006?uselang=en", :type => :wikidata_link, :page => "Q4006" }, links[4])

    links = TagParser.wikidata_links("source:species:wikidata", "PlantNet.org AI")
    assert_nil links
  end

  def test_wikipedia_links
    links = TagParser.wikipedia_links("wikipedia", "http://en.wikipedia.org/wiki/Full%20URL")
    assert_nil links

    links = TagParser.wikipedia_links("wikipedia", "https://en.wikipedia.org/wiki/Full%20URL")
    assert_nil links

    links = TagParser.wikipedia_links("wikipedia", "Test")
    assert_nil links

    links = TagParser.wikipedia_links("wikipedia", "de:Test")
    assert_equal 1, links.length
    assert_equal({ :text => "de:Test", :url => "https://de.wikipedia.org/wiki/Test?uselang=en", :type => :wikipedia_link, :page => "de:Test" }, links[0])

    links = TagParser.wikipedia_links("wikipedia:fr", "Portsea")
    assert_equal 1, links.length
    assert_equal({ :text => "Portsea", :url => "https://fr.wikipedia.org/wiki/Portsea?uselang=en", :type => :wikipedia_link, :page => "Portsea" }, links[0])

    links = TagParser.wikipedia_links("wikipedia:fr", "de:Test")
    assert_equal 1, links.length
    assert_equal({ :text => "de:Test", :url => "https://de.wikipedia.org/wiki/Test?uselang=en", :type => :wikipedia_link, :page => "de:Test" }, links[0])

    links = TagParser.wikipedia_links("wikipedia", "de:Englischer Garten (München)#Japanisches Teehaus")
    assert_equal 1, links.length
    assert_equal({
                   :text => "de:Englischer Garten (München)#Japanisches Teehaus",
                   :url => "https://de.wikipedia.org/wiki/Englischer_Garten_%28M%C3%BCnchen%29?uselang=en#Japanisches_Teehaus",
                   :type => :wikipedia_link,
                   :page => "de:Englischer Garten (München)#Japanisches Teehaus"
                 }, links[0])

    links = TagParser.wikipedia_links("wikipedia", "de:Alte Brücke (Heidelberg)#Brückenaffe")
    assert_equal 1, links.length
    assert_equal({
                   :text => "de:Alte Brücke (Heidelberg)#Brückenaffe",
                   :url => "https://de.wikipedia.org/wiki/Alte_Br%C3%BCcke_%28Heidelberg%29?uselang=en#Br%C3%BCckenaffe",
                   :type => :wikipedia_link,
                   :page => "de:Alte Brücke (Heidelberg)#Brückenaffe"
                 }, links[0])

    links = TagParser.wikipedia_links("wikipedia", "de:Liste der Baudenkmäler in Eichstätt#Brückenstraße 1, Ehemaliges Bauernhaus")
    assert_equal 1, links.length
    assert_equal({
                   :text => "de:Liste der Baudenkmäler in Eichstätt#Brückenstraße 1, Ehemaliges Bauernhaus",
                   :url => "https://de.wikipedia.org/wiki/Liste_der_Baudenkm%C3%A4ler_in_Eichst%C3%A4tt?uselang=en#Br%C3%BCckenstra%C3%9Fe_1%2C_Ehemaliges_Bauernhaus",
                   :type => :wikipedia_link,
                   :page => "de:Liste der Baudenkmäler in Eichstätt#Brückenstraße 1, Ehemaliges Bauernhaus"
                 }, links[0])

    links = TagParser.wikipedia_links("wikipedia", "en:Are Years What? (for Marianne Moore)")
    assert_equal 1, links.length
    assert_equal({
                   :text => "en:Are Years What? (for Marianne Moore)",
                   :url => "https://en.wikipedia.org/wiki/Are_Years_What%3F_%28for_Marianne_Moore%29?uselang=en",
                   :type => :wikipedia_link,
                   :page => "en:Are Years What? (for Marianne Moore)"
                 }, links[0])

    I18n.with_locale "pt-BR" do
      links = TagParser.wikipedia_links("wikipedia", "zh-classical:Test#Section")
      assert_equal 1, links.length
      assert_equal({ :text => "zh-classical:Test#Section", :url => "https://zh-classical.wikipedia.org/wiki/Test?uselang=pt-BR#Section", :type => :wikipedia_link, :page => "zh-classical:Test#Section" }, links[0])
    end

    links = TagParser.wikipedia_links("subject:wikipedia", "en:Catherine McAuley")
    assert_equal 1, links.length
    assert_equal({ :text => "en:Catherine McAuley", :url => "https://en.wikipedia.org/wiki/Catherine_McAuley?uselang=en", :type => :wikipedia_link, :page => "en:Catherine McAuley" }, links[0])

    links = TagParser.wikipedia_links("artist:wikipedia", "en:Pablo Picasso")
    assert_equal 1, links.length
    assert_equal({ :text => "en:Pablo Picasso", :url => "https://en.wikipedia.org/wiki/Pablo_Picasso?uselang=en", :type => :wikipedia_link, :page => "en:Pablo Picasso" }, links[0])

    links = TagParser.wikipedia_links("architect:wikipedia", "en:Frank Lloyd Wright")
    assert_equal 1, links.length
    assert_equal({ :text => "en:Frank Lloyd Wright", :url => "https://en.wikipedia.org/wiki/Frank_Lloyd_Wright?uselang=en", :type => :wikipedia_link, :page => "en:Frank Lloyd Wright" }, links[0])

    links = TagParser.wikipedia_links("buried:wikipedia", "en:Stephen Hawking")
    assert_equal 1, links.length
    assert_equal({ :text => "en:Stephen Hawking", :url => "https://en.wikipedia.org/wiki/Stephen_Hawking?uselang=en", :type => :wikipedia_link, :page => "en:Stephen Hawking" }, links[0])

    links = TagParser.wikipedia_links("foo", "Test")
    assert_nil links

    # Multiple values separated by ;
    links = TagParser.wikipedia_links("wikipedia", "Test;Hello")
    assert_nil links

    links = TagParser.wikipedia_links("wikipedia", "de:Berlin;en:London;fr:Paris")
    assert_equal 3, links.length
    assert_equal({ :text => "de:Berlin", :url => "https://de.wikipedia.org/wiki/Berlin?uselang=en", :type => :wikipedia_link, :page => "de:Berlin" }, links[0])
    assert_equal({ :text => "en:London", :url => "https://en.wikipedia.org/wiki/London?uselang=en", :type => :wikipedia_link, :page => "en:London" }, links[1])
    assert_equal({ :text => "fr:Paris", :url => "https://fr.wikipedia.org/wiki/Paris?uselang=en", :type => :wikipedia_link, :page => "fr:Paris" }, links[2])

    links = TagParser.wikipedia_links("fixme:wikipedia", "The wikipedia tag links to a list article, not an article about this specific feature.")
    assert_nil links
  end

  def test_wikimedia_commons_link
    links = TagParser.wikimedia_commons_link("wikimedia_commons", "http://commons.wikimedia.org/wiki/File:Full%20URL.jpg")
    assert_nil links

    links = TagParser.wikimedia_commons_link("wikimedia_commons", "https://commons.wikimedia.org/wiki/File:Full%20URL.jpg")
    assert_nil links

    links = TagParser.wikimedia_commons_link("wikimedia_commons", "Test.jpg")
    assert_nil links

    links = TagParser.wikimedia_commons_link("wikimedia_commons", "File:Test.jpg")
    assert_equal 1, links.length
    assert_equal({ :text => "File:Test.jpg", :url => "https://commons.wikimedia.org/wiki/File:Test.jpg?uselang=en", :type => :wikimedia_commons_link, :page => "File:Test.jpg" }, links[0])

    links = TagParser.wikimedia_commons_link("wikimedia_commons", "Category:Test_Category")
    assert_equal 1, links.length
    assert_equal({ :text => "Category:Test_Category", :url => "https://commons.wikimedia.org/wiki/Category:Test_Category?uselang=en", :type => :wikimedia_commons_link, :page => "Category:Test_Category" }, links[0])

    links = TagParser.wikimedia_commons_link("wikimedia_commons", "Category:What If? (Bonn)")
    assert_equal 1, links.length
    assert_equal({ :text => "Category:What If? (Bonn)", :url => "https://commons.wikimedia.org/wiki/Category:What%20If%3F%20%28Bonn%29?uselang=en", :type => :wikimedia_commons_link, :page => "Category:What If? (Bonn)" }, links[0])

    links = TagParser.wikimedia_commons_link("wikimedia_commons", "File:Corsica-vizzavona-abri-southwell.jpg#mediaviewer/File:Corsica-vizzavona-abri-southwell.jpg")
    assert_equal 1, links.length
    assert_equal({
                   :text => "File:Corsica-vizzavona-abri-southwell.jpg#mediaviewer/File:Corsica-vizzavona-abri-southwell.jpg",
                   :url => "https://commons.wikimedia.org/wiki/File:Corsica-vizzavona-abri-southwell.jpg?uselang=en",
                   :type => :wikimedia_commons_link,
                   :page => "File:Corsica-vizzavona-abri-southwell.jpg#mediaviewer/File:Corsica-vizzavona-abri-southwell.jpg"
                 }, links[0])

    # Reject namespaces other than File and Category
    links = TagParser.wikimedia_commons_link("wikimedia_commons", "Commons:Featured pictures")
    assert_nil links

    # Secondary Wikimedia Commons links
    links = TagParser.wikimedia_commons_link("artist:wikimedia_commons", "File:Unknown Artist Portrait.jpg")
    assert_equal 1, links.length
    assert_equal({ :text => "File:Unknown Artist Portrait.jpg", :url => "https://commons.wikimedia.org/wiki/File:Unknown%20Artist%20Portrait.jpg?uselang=en", :type => :wikimedia_commons_link, :page => "File:Unknown Artist Portrait.jpg" }, links[0])

    I18n.with_locale "pt-BR" do
      links = TagParser.wikimedia_commons_link("wikimedia_commons", "File:Test.jpg")
      assert_equal 1, links.length
      assert_equal({ :text => "File:Test.jpg", :url => "https://commons.wikimedia.org/wiki/File:Test.jpg?uselang=pt-BR", :type => :wikimedia_commons_link, :page => "File:Test.jpg" }, links[0])
    end

    links = TagParser.wikimedia_commons_link("foo", "Test")
    assert_nil links
  end

  def test_email_link
    links = TagParser.email_link("foo", "Test")
    assert_nil links

    links = TagParser.email_link("email", "123")
    assert_nil links

    links = TagParser.email_link("email", "Abc.example.com")
    assert_nil links

    links = TagParser.email_link("email", "a@b@c.com")
    assert_nil links

    links = TagParser.email_link("email", "just\"not\"right@example.com")
    assert_nil links

    links = TagParser.email_link("email", "123 abcdefg@space.com")
    assert_nil links

    links = TagParser.email_link("email", "test@ abc")
    assert_nil links

    links = TagParser.email_link("email", "using;semicolon@test.com")
    assert_nil links

    links = TagParser.email_link("email", "x@example.com")
    assert_equal 1, links.length
    assert_equal({ :text => "x@example.com", :url => "x@example.com", :type => :email_link, :email => "x@example.com" }, links[0])

    links = TagParser.email_link("email", "other.email-with-hyphen@example.com")
    assert_equal 1, links.length
    assert_equal({ :text => "other.email-with-hyphen@example.com", :url => "other.email-with-hyphen@example.com", :type => :email_link, :email => "other.email-with-hyphen@example.com" }, links[0])

    links = TagParser.email_link("email", "user.name+tag+sorting@example.com")
    assert_equal 1, links.length
    assert_equal({ :text => "user.name+tag+sorting@example.com", :url => "user.name+tag+sorting@example.com", :type => :email_link, :email => "user.name+tag+sorting@example.com" }, links[0])

    links = TagParser.email_link("email", "dash-in@both-parts.com")
    assert_equal 1, links.length
    assert_equal({ :text => "dash-in@both-parts.com", :url => "dash-in@both-parts.com", :type => :email_link, :email => "dash-in@both-parts.com" }, links[0])

    links = TagParser.email_link("email", "example@s.example")
    assert_equal 1, links.length
    assert_equal({ :text => "example@s.example", :url => "example@s.example", :type => :email_link, :email => "example@s.example" }, links[0])

    # Strips whitespace at ends
    links = TagParser.email_link("email", " test@email.com ")
    assert_equal 1, links.length
    assert_equal({ :text => "test@email.com", :url => "test@email.com", :type => :email_link, :email => "test@email.com" }, links[0])

    links = TagParser.email_link("contact:email", "example@example.com")
    assert_equal 1, links.length
    assert_equal({ :text => "example@example.com", :url => "example@example.com", :type => :email_link, :email => "example@example.com" }, links[0])

    links = TagParser.email_link("maxweight:conditional", "none@agricultural")
    assert_nil links
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
    assert_equal({ :text => "+1234567890", :url => "tel:+1234567890", :type => :telephone_link, :phone_number => "+1234567890" }, links[0])

    links = TagParser.telephone_links("phone", "+1234-567-890")
    assert_equal 1, links.length
    assert_equal({ :text => "+1234-567-890", :url => "tel:+1234-567-890", :type => :telephone_link, :phone_number => "+1234-567-890" }, links[0])

    links = TagParser.telephone_links("phone", "+1234/567/890")
    assert_equal 1, links.length
    assert_equal({ :text => "+1234/567/890", :url => "tel:+1234/567/890", :type => :telephone_link, :phone_number => "+1234/567/890" }, links[0])

    links = TagParser.telephone_links("phone", "+1234.567.890")
    assert_equal 1, links.length
    assert_equal({ :text => "+1234.567.890", :url => "tel:+1234.567.890", :type => :telephone_link, :phone_number => "+1234.567.890" }, links[0])

    links = TagParser.telephone_links("phone", "   +1234 567-890	")
    assert_equal 1, links.length
    assert_equal({ :text => "+1234 567-890", :url => "tel:+1234567-890", :type => :telephone_link, :phone_number => "+1234 567-890" }, links[0])

    links = TagParser.telephone_links("phone", "+1 234-567-890")
    assert_equal 1, links.length
    assert_equal({ :text => "+1 234-567-890", :url => "tel:+1234-567-890", :type => :telephone_link, :phone_number => "+1 234-567-890" }, links[0])

    links = TagParser.telephone_links("phone", "+1 (234) 567-890")
    assert_equal 1, links.length
    assert_equal({ :text => "+1 (234) 567-890", :url => "tel:+1(234)567-890", :type => :telephone_link, :phone_number => "+1 (234) 567-890" }, links[0])

    # Multiple valid phone numbers separated by ;
    links = TagParser.telephone_links("phone", "+1234567890; +22334455667788")
    assert_equal 2, links.length
    assert_equal({ :text => "+1234567890", :url => "tel:+1234567890", :type => :telephone_link, :phone_number => "+1234567890" }, links[0])
    assert_equal({ :text => "+22334455667788", :url => "tel:+22334455667788", :type => :telephone_link, :phone_number => "+22334455667788" }, links[1])

    links = TagParser.telephone_links("phone", "+1 (234) 567-890 ;  +22(33)4455.66.7788 ")
    assert_equal 2, links.length
    assert_equal({ :text => "+1 (234) 567-890", :url => "tel:+1(234)567-890", :type => :telephone_link, :phone_number => "+1 (234) 567-890" }, links[0])
    assert_equal({ :text => "+22(33)4455.66.7788", :url => "tel:+22(33)4455.66.7788", :type => :telephone_link, :phone_number => "+22(33)4455.66.7788" }, links[1])
  end

  def test_colour_preview
    # basic positive tests
    links = TagParser.colour_preview("colour", "red")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "red" }, links[0])
    assert_equal({ :text => "red" }, links[1])

    links = TagParser.colour_preview("colour", "Red")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "Red" }, links[0])
    assert_equal({ :text => "Red" }, links[1])

    links = TagParser.colour_preview("colour", "darkRed")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "darkRed" }, links[0])
    assert_equal({ :text => "darkRed" }, links[1])

    links = TagParser.colour_preview("colour", "#f00")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "#f00" }, links[0])
    assert_equal({ :text => "#f00" }, links[1])

    links = TagParser.colour_preview("colour", "#fF0000")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "#fF0000" }, links[0])
    assert_equal({ :text => "#fF0000" }, links[1])

    # other tag variants:
    links = TagParser.colour_preview("building:colour", "#f00")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "#f00" }, links[0])
    assert_equal({ :text => "#f00" }, links[1])

    links = TagParser.colour_preview("ref:colour", "#f00")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "#f00" }, links[0])
    assert_equal({ :text => "#f00" }, links[1])

    links = TagParser.colour_preview("int_ref:colour", "green")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "green" }, links[0])
    assert_equal({ :text => "green" }, links[1])

    links = TagParser.colour_preview("roof:colour", "#f00")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "#f00" }, links[0])
    assert_equal({ :text => "#f00" }, links[1])

    links = TagParser.colour_preview("seamark:beacon_lateral:colour", "#f00")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "#f00" }, links[0])
    assert_equal({ :text => "#f00" }, links[1])

    # negative tests:
    links = TagParser.colour_preview("colour", "")
    assert_nil links

    links = TagParser.colour_preview("colour", "   ")
    assert_nil links

    links = TagParser.colour_preview("colour", nil)
    assert_nil links

    # ignore US spelling variant
    links = TagParser.colour_preview("color", "red")
    assert_nil links

    # irrelevant tag names
    links = TagParser.colour_preview("building", "red")
    assert_nil links

    links = TagParser.colour_preview("ref:colour_no", "red")
    assert_nil links

    links = TagParser.colour_preview("ref:colour-bg", "red")
    assert_nil links

    links = TagParser.colour_preview("int_ref", "red")
    assert_nil links

    # invalid hex codes
    links = TagParser.colour_preview("colour", "#")
    assert_nil links

    links = TagParser.colour_preview("colour", "#ff")
    assert_nil links

    links = TagParser.colour_preview("colour", "#ffff")
    assert_nil links

    links = TagParser.colour_preview("colour", "#fffffff")
    assert_nil links

    links = TagParser.colour_preview("colour", "#ggg")
    assert_nil links

    links = TagParser.colour_preview("colour", "#ff 00 00")
    assert_nil links

    # invalid w3c color names:
    links = TagParser.colour_preview("colour", "r")
    assert_nil links

    links = TagParser.colour_preview("colour", "ffffff")
    assert_nil links

    links = TagParser.colour_preview("colour", "f00")
    assert_nil links

    links = TagParser.colour_preview("colour", "xxxred")
    assert_nil links

    links = TagParser.colour_preview("colour", "dark red")
    assert_nil links

    links = TagParser.colour_preview("colour", "dark_red")
    assert_nil links

    links = TagParser.colour_preview("colour", "ADarkDummyLongColourNameWithAPurpleUndertone")
    assert_nil links
  end

  def test_basic_link
    assert_nil TagParser.basic_link("website", "https://example.com/page")[:url]

    assert_nil TagParser.basic_link("nonexistent_key", "SomeValue")[:url]

    url = TagParser.basic_link("wikidata", "Q936")[:url]
    assert_equal "https://www.wikidata.org/entity/Q936", url

    url = TagParser.basic_link("hashtags", "#maproulette")[:url]
    assert_equal "https://resultmaps.neis-one.org/osm-changesets?comment=maproulette", url
  end

  def test_basic_link_encodes_query_values
    url = TagParser.basic_link("opening_hours", "easter +6 days off \"Ostern\"; Mo-Fr 08:00-12:00 & 13:00-17:00 #1")[:url]
    assert_equal "https://openingh.openstreetmap.de/evaluation_tool/?EXP=easter%20%2B6%20days%20off%20%22Ostern%22%3B%20Mo-Fr%2008%3A00-12%3A00%20%26%2013%3A00-17%3A00%20%231", url
  end

  def test_build_tag2link_dict_rejects_deprecated_and_third_party
    data = [
      { "key" => "Key:example", "url" => "http://example.com/$1", "rank" => "deprecated", "source" => "osmwiki:P8" },
      { "key" => "Key:example2", "url" => "http://example2.com/$1", "rank" => "preferred", "source" => "wikidata:P3303" },
      { "key" => "Key:example3", "url" => "http://example3.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" }
    ]
    dict = TagParser.build_tag2link_dict(data)
    assert_not_includes dict, "example"
    assert_not_includes dict, "example2"
    assert_includes dict, "example3"
  end

  def test_build_tag2link_dict_chooses_single_preferred_item
    data = [
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "normal", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" }
    ]
    dict = TagParser.build_tag2link_dict(data)
    assert_equal "http://example.com/$1", dict["example"]

    data = [
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example.com/$1", "rank" => "preferred", "source" => "wikidata:P1630" },
      { "key" => "Key:example", "url" => "http://example3.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" }
    ]
    dict = TagParser.build_tag2link_dict(data)
    assert_equal "http://example.com/$1", dict["example"]

    data = [
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" }
    ]
    dict = TagParser.build_tag2link_dict(data)
    assert_equal "http://example2.com/$1", dict["example"]
  end

  def test_build_tag2link_dict_deduplicates_urls
    data = [
      { "key" => "Key:example", "url" => "http://example.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example.com/$1", "rank" => "normal", "source" => "wikidata:P1630" }
    ]
    dict = TagParser.build_tag2link_dict(data)
    assert_equal "http://example.com/$1", dict["example"]
  end

  def test_build_tag2link_dict_rejects_multiple_equally_preferred_items
    data = [
      { "key" => "Key:example", "url" => "http://example1.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" }
    ]
    dict = TagParser.build_tag2link_dict(data)
    assert_not_includes dict, "example"

    data = [
      { "key" => "Key:example", "url" => "http://example1.com/$1", "rank" => "normal", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "normal", "source" => "osmwiki:P8" }
    ]
    dict = TagParser.build_tag2link_dict(data)
    assert_not_includes dict, "example"
  end

  def test_build_tag2link_dict_chooses_osmwiki_when_both_have_single_preferred
    data = [
      { "key" => "Key:example", "url" => "http://example1.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "preferred", "source" => "wikidata:P1630" }
    ]
    dict = TagParser.build_tag2link_dict(data)
    assert_equal "http://example1.com/$1", dict["example"]

    data = [
      { "key" => "Key:example", "url" => "http://example1.com/$1", "rank" => "normal", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "normal", "source" => "wikidata:P1630" }
    ]
    dict = TagParser.build_tag2link_dict(data)
    assert_equal "http://example1.com/$1", dict["example"]
  end

  def test_build_tag2link_dict_multiple_sources_more_than_two
    data = [
      { "key" => "Key:example", "url" => "http://example1.com/$1", "rank" => "normal", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "normal", "source" => "wikidata:P1630" },
      { "key" => "Key:example", "url" => "http://example3.com/$1", "rank" => "normal", "source" => "other:source" }
    ]
    dict = TagParser.build_tag2link_dict(data)
    # Should not happen with current tag2link schema, but ensure we handle it gracefully
    assert_not_includes dict, "example"
  end
end
