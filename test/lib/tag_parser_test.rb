# frozen_string_literal: true

require "test_helper"

class TagParserTest < ActiveSupport::TestCase
  def test_parse_key
    link = TagParser.parse_key("highway")
    assert_equal({ :text => "highway", :url => "https://wiki.openstreetmap.org/wiki/Key:highway?uselang=en", :type => :"wiki_link.key", :key => "highway" }, link)

    I18n.with_locale "de" do
      link = TagParser.parse_key("highway")
      assert_equal({ :text => "highway", :url => "https://wiki.openstreetmap.org/wiki/DE:Key:highway?uselang=de", :type => :"wiki_link.key", :key => "highway" }, link)
    end

    I18n.with_locale "tr" do
      link = TagParser.parse_key("highway")
      assert_equal({ :text => "highway", :url => "https://wiki.openstreetmap.org/wiki/Tr:Key:highway?uselang=tr", :type => :"wiki_link.key", :key => "highway" }, link)
    end
  end

  def test_parse_value_osm_wiki_links
    links = TagParser.parse_value("highway", "primary")
    assert_equal [{ :text => "primary", :url => "https://wiki.openstreetmap.org/wiki/Tag:highway=primary?uselang=en", :type => :"wiki_link.tag", :key => "highway", :value => "primary" }], links

    I18n.with_locale "de" do
      links = TagParser.parse_value("highway", "primary")
      assert_equal [{ :text => "primary", :url => "https://wiki.openstreetmap.org/wiki/DE:Tag:highway=primary?uselang=de", :type => :"wiki_link.tag", :key => "highway", :value => "primary" }], links
    end

    I18n.with_locale "tr" do
      links = TagParser.parse_value("highway", "path")
      assert_equal [{ :text => "path", :url => "https://wiki.openstreetmap.org/wiki/Tag:highway=path?uselang=tr", :type => :"wiki_link.tag", :key => "highway", :value => "path" }], links
    end
  end

  def test_parse_value_wikidata_links
    # Non-wikidata tag
    links = TagParser.parse_value("foo", "Test")
    assert_not_equal :wikidata_link, links[0][:type]

    # No URLs allowed
    links = TagParser.parse_value("wikidata", "http://www.wikidata.org/entity/Q1")
    assert_not_equal :wikidata_link, links[0][:type]

    # No language-prefixes (as wikidata is multilanguage)
    links = TagParser.parse_value("wikidata", "en:Q1")
    assert_not_equal :wikidata_link, links[0][:type]

    # Needs a leading Q
    links = TagParser.parse_value("wikidata", "1")
    assert_not_equal :wikidata_link, links[0][:type]

    # No leading zeros allowed
    links = TagParser.parse_value("wikidata", "Q0123")
    assert_not_equal :wikidata_link, links[0][:type]

    # A valid value
    links = TagParser.parse_value("wikidata", "Q42")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :wikidata_preview, :qids => ["Q42"], :count => 1 }, links[0])
    assert_equal({ :text => "Q42", :url => "https://www.wikidata.org/entity/Q42?uselang=en", :type => :wikidata_link, :page => "Q42" }, links[1])

    # the language of the wikidata-page should match the current locale
    I18n.with_locale "zh-CN" do
      links = TagParser.parse_value("wikidata", "Q1234")
      assert_equal 2, links.length
      assert_equal({ :type => :html, :widget => :wikidata_preview, :qids => ["Q1234"], :count => 1 }, links[0])
      assert_equal({ :text => "Q1234", :url => "https://www.wikidata.org/entity/Q1234?uselang=zh-CN", :type => :wikidata_link, :page => "Q1234" }, links[1])
    end
  end

  def test_parse_value_wikidata_links_secondary
    links = TagParser.parse_value("operator:wikidata", "Q24")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :wikidata_preview, :qids => ["Q24"], :count => 1 }, links[0])
    assert_equal({ :text => "Q24", :url => "https://www.wikidata.org/entity/Q24?uselang=en", :type => :wikidata_link, :page => "Q24" }, links[1])

    links = TagParser.parse_value("buried:wikidata", "Q24")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :wikidata_preview, :qids => ["Q24"], :count => 1 }, links[0])
    assert_equal({ :text => "Q24", :url => "https://www.wikidata.org/entity/Q24?uselang=en", :type => :wikidata_link, :page => "Q24" }, links[1])

    links = TagParser.parse_value("species:wikidata", "Q26899")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :wikidata_preview, :qids => ["Q26899"], :count => 1 }, links[0])
    assert_equal({ :text => "Q26899", :url => "https://www.wikidata.org/entity/Q26899?uselang=en", :type => :wikidata_link, :page => "Q26899" }, links[1])

    links = TagParser.parse_value("name:etymology:wikidata", "Q121745508")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :wikidata_preview, :qids => ["Q121745508"], :count => 1 }, links[0])
    assert_equal({ :text => "Q121745508", :url => "https://www.wikidata.org/entity/Q121745508?uselang=en", :type => :wikidata_link, :page => "Q121745508" }, links[1])

    # Another one with multiple values and I18n
    I18n.with_locale "dsb" do
      links = TagParser.parse_value("brand:wikidata", "Q936;Q2013;Q1568346")
      assert_equal 4, links.length
      assert_equal({ :type => :html, :widget => :wikidata_preview, :qids => %w[Q936 Q2013 Q1568346], :count => 3 }, links[0])
      assert_equal({ :text => "Q936", :url => "https://www.wikidata.org/entity/Q936?uselang=dsb", :type => :wikidata_link, :page => "Q936" }, links[1])
      assert_equal({ :text => "Q2013", :url => "https://www.wikidata.org/entity/Q2013?uselang=dsb", :type => :wikidata_link, :page => "Q2013" }, links[2])
      assert_equal({ :text => "Q1568346", :url => "https://www.wikidata.org/entity/Q1568346?uselang=dsb", :type => :wikidata_link, :page => "Q1568346" }, links[3])
    end

    # and now with whitespaces...
    links = TagParser.parse_value("subject:wikidata", "Q6542248 ;\tQ180\n ;\rQ364\t\n\r ;\nQ4006")
    assert_equal 5, links.length
    assert_equal({ :type => :html, :widget => :wikidata_preview, :qids => %w[Q6542248 Q180 Q364 Q4006], :count => 4 }, links[0])
    assert_equal({ :text => "Q6542248 ", :url => "https://www.wikidata.org/entity/Q6542248?uselang=en", :type => :wikidata_link, :page => "Q6542248" }, links[1])
    assert_equal({ :text => "\tQ180\n ", :url => "https://www.wikidata.org/entity/Q180?uselang=en", :type => :wikidata_link, :page => "Q180" }, links[2])
    assert_equal({ :text => "\rQ364\t\n\r ", :url => "https://www.wikidata.org/entity/Q364?uselang=en", :type => :wikidata_link, :page => "Q364" }, links[3])
    assert_equal({ :text => "\nQ4006", :url => "https://www.wikidata.org/entity/Q4006?uselang=en", :type => :wikidata_link, :page => "Q4006" }, links[4])

    links = TagParser.parse_value("source:species:wikidata", "PlantNet.org AI")
    assert_not_equal :wikidata_link, links[0][:type]
  end

  def test_parse_value_wikipedia_links
    links = TagParser.parse_value("wikipedia", "http://en.wikipedia.org/wiki/Full%20URL")
    assert_not_equal :wikipedia_link, links[0][:type]

    links = TagParser.parse_value("wikipedia", "https://en.wikipedia.org/wiki/Full%20URL")
    assert_not_equal :wikipedia_link, links[0][:type]

    links = TagParser.parse_value("wikipedia", "Test")
    assert_not_equal :wikipedia_link, links[0][:type]

    links = TagParser.parse_value("wikipedia", "de:Test")
    assert_equal 1, links.length
    assert_equal({ :text => "de:Test", :url => "https://de.wikipedia.org/wiki/Test?uselang=en", :type => :wikipedia_link, :page => "de:Test" }, links[0])

    links = TagParser.parse_value("wikipedia:fr", "Portsea")
    assert_equal 1, links.length
    assert_equal({ :text => "Portsea", :url => "https://fr.wikipedia.org/wiki/Portsea?uselang=en", :type => :wikipedia_link, :page => "Portsea" }, links[0])

    links = TagParser.parse_value("wikipedia:fr", "de:Test")
    assert_equal 1, links.length
    assert_equal({ :text => "de:Test", :url => "https://de.wikipedia.org/wiki/Test?uselang=en", :type => :wikipedia_link, :page => "de:Test" }, links[0])

    links = TagParser.parse_value("wikipedia", "de:Englischer Garten (München)#Japanisches Teehaus")
    assert_equal 1, links.length
    assert_equal({
                   :text => "de:Englischer Garten (München)#Japanisches Teehaus",
                   :url => "https://de.wikipedia.org/wiki/Englischer_Garten_%28M%C3%BCnchen%29?uselang=en#Japanisches_Teehaus",
                   :type => :wikipedia_link,
                   :page => "de:Englischer Garten (München)#Japanisches Teehaus"
                 }, links[0])

    links = TagParser.parse_value("wikipedia", "de:Alte Brücke (Heidelberg)#Brückenaffe")
    assert_equal 1, links.length
    assert_equal({
                   :text => "de:Alte Brücke (Heidelberg)#Brückenaffe",
                   :url => "https://de.wikipedia.org/wiki/Alte_Br%C3%BCcke_%28Heidelberg%29?uselang=en#Br%C3%BCckenaffe",
                   :type => :wikipedia_link,
                   :page => "de:Alte Brücke (Heidelberg)#Brückenaffe"
                 }, links[0])

    links = TagParser.parse_value("wikipedia", "de:Liste der Baudenkmäler in Eichstätt#Brückenstraße 1, Ehemaliges Bauernhaus")
    assert_equal 1, links.length
    assert_equal({
                   :text => "de:Liste der Baudenkmäler in Eichstätt#Brückenstraße 1, Ehemaliges Bauernhaus",
                   :url => "https://de.wikipedia.org/wiki/Liste_der_Baudenkm%C3%A4ler_in_Eichst%C3%A4tt?uselang=en#Br%C3%BCckenstra%C3%9Fe_1%2C_Ehemaliges_Bauernhaus",
                   :type => :wikipedia_link,
                   :page => "de:Liste der Baudenkmäler in Eichstätt#Brückenstraße 1, Ehemaliges Bauernhaus"
                 }, links[0])

    links = TagParser.parse_value("wikipedia", "en:Are Years What? (for Marianne Moore)")
    assert_equal 1, links.length
    assert_equal({
                   :text => "en:Are Years What? (for Marianne Moore)",
                   :url => "https://en.wikipedia.org/wiki/Are_Years_What%3F_%28for_Marianne_Moore%29?uselang=en",
                   :type => :wikipedia_link,
                   :page => "en:Are Years What? (for Marianne Moore)"
                 }, links[0])

    I18n.with_locale "pt-BR" do
      links = TagParser.parse_value("wikipedia", "zh-classical:Test#Section")
      assert_equal 1, links.length
      assert_equal({ :text => "zh-classical:Test#Section", :url => "https://zh-classical.wikipedia.org/wiki/Test?uselang=pt-BR#Section", :type => :wikipedia_link, :page => "zh-classical:Test#Section" }, links[0])
    end

    # Multiple values separated by ;
    links = TagParser.parse_value("wikipedia", "Test;Hello")
    assert_not_equal :wikipedia_link, links[0][:type]

    links = TagParser.parse_value("wikipedia", "de:Berlin;en:London;fr:Paris")
    assert_equal 3, links.length
    assert_equal({ :text => "de:Berlin", :url => "https://de.wikipedia.org/wiki/Berlin?uselang=en", :type => :wikipedia_link, :page => "de:Berlin" }, links[0])
    assert_equal({ :text => "en:London", :url => "https://en.wikipedia.org/wiki/London?uselang=en", :type => :wikipedia_link, :page => "en:London" }, links[1])
    assert_equal({ :text => "fr:Paris", :url => "https://fr.wikipedia.org/wiki/Paris?uselang=en", :type => :wikipedia_link, :page => "fr:Paris" }, links[2])
  end

  def test_parse_value_wikipedia_links_secondary
    links = TagParser.parse_value("subject:wikipedia", "en:Catherine McAuley")
    assert_equal 1, links.length
    assert_equal({ :text => "en:Catherine McAuley", :url => "https://en.wikipedia.org/wiki/Catherine_McAuley?uselang=en", :type => :wikipedia_link, :page => "en:Catherine McAuley" }, links[0])

    links = TagParser.parse_value("artist:wikipedia", "en:Pablo Picasso")
    assert_equal 1, links.length
    assert_equal({ :text => "en:Pablo Picasso", :url => "https://en.wikipedia.org/wiki/Pablo_Picasso?uselang=en", :type => :wikipedia_link, :page => "en:Pablo Picasso" }, links[0])

    links = TagParser.parse_value("architect:wikipedia", "en:Frank Lloyd Wright")
    assert_equal 1, links.length
    assert_equal({ :text => "en:Frank Lloyd Wright", :url => "https://en.wikipedia.org/wiki/Frank_Lloyd_Wright?uselang=en", :type => :wikipedia_link, :page => "en:Frank Lloyd Wright" }, links[0])

    links = TagParser.parse_value("buried:wikipedia", "en:Stephen Hawking")
    assert_equal 1, links.length
    assert_equal({ :text => "en:Stephen Hawking", :url => "https://en.wikipedia.org/wiki/Stephen_Hawking?uselang=en", :type => :wikipedia_link, :page => "en:Stephen Hawking" }, links[0])

    links = TagParser.parse_value("foo", "Test")
    assert_not_equal :wikipedia_link, links[0][:type]

    links = TagParser.parse_value("fixme:wikipedia", "The wikipedia tag links to a list article, not an article about this specific feature.")
    assert_not_equal :wikipedia_link, links[0][:type]
  end

  def test_parse_value_wikimedia_commons_links
    links = TagParser.parse_value("wikimedia_commons", "http://commons.wikimedia.org/wiki/File:Full%20URL.jpg")
    assert_not_equal :wikimedia_commons_link, links[0][:type]

    links = TagParser.parse_value("wikimedia_commons", "https://commons.wikimedia.org/wiki/File:Full%20URL.jpg")
    assert_not_equal :wikimedia_commons_link, links[0][:type]

    links = TagParser.parse_value("wikimedia_commons", "Test.jpg")
    assert_not_equal :wikimedia_commons_link, links[0][:type]

    links = TagParser.parse_value("wikimedia_commons", "File:Test.jpg")
    assert_equal 1, links.length
    assert_equal({ :text => "File:Test.jpg", :url => "https://commons.wikimedia.org/wiki/File:Test.jpg?uselang=en", :type => :wikimedia_commons_link, :page => "File:Test.jpg" }, links[0])

    links = TagParser.parse_value("wikimedia_commons", "Category:Test_Category")
    assert_equal 1, links.length
    assert_equal({ :text => "Category:Test_Category", :url => "https://commons.wikimedia.org/wiki/Category:Test_Category?uselang=en", :type => :wikimedia_commons_link, :page => "Category:Test_Category" }, links[0])

    links = TagParser.parse_value("wikimedia_commons", "Category:What If? (Bonn)")
    assert_equal 1, links.length
    assert_equal({ :text => "Category:What If? (Bonn)", :url => "https://commons.wikimedia.org/wiki/Category:What%20If%3F%20%28Bonn%29?uselang=en", :type => :wikimedia_commons_link, :page => "Category:What If? (Bonn)" }, links[0])

    links = TagParser.parse_value("wikimedia_commons", "File:Corsica-vizzavona-abri-southwell.jpg#mediaviewer/File:Corsica-vizzavona-abri-southwell.jpg")
    assert_equal 1, links.length
    assert_equal({
                   :text => "File:Corsica-vizzavona-abri-southwell.jpg#mediaviewer/File:Corsica-vizzavona-abri-southwell.jpg",
                   :url => "https://commons.wikimedia.org/wiki/File:Corsica-vizzavona-abri-southwell.jpg?uselang=en",
                   :type => :wikimedia_commons_link,
                   :page => "File:Corsica-vizzavona-abri-southwell.jpg#mediaviewer/File:Corsica-vizzavona-abri-southwell.jpg"
                 }, links[0])

    # Reject namespaces other than File and Category
    links = TagParser.parse_value("wikimedia_commons", "Commons:Featured pictures")
    assert_not_equal :wikimedia_commons_link, links[0][:type]
  end

  def test_parse_value_wikimedia_commons_links_secondary
    links = TagParser.parse_value("artist:wikimedia_commons", "File:Unknown Artist Portrait.jpg")
    assert_equal 1, links.length
    assert_equal({ :text => "File:Unknown Artist Portrait.jpg", :url => "https://commons.wikimedia.org/wiki/File:Unknown%20Artist%20Portrait.jpg?uselang=en", :type => :wikimedia_commons_link, :page => "File:Unknown Artist Portrait.jpg" }, links[0])

    I18n.with_locale "pt-BR" do
      links = TagParser.parse_value("wikimedia_commons", "File:Test.jpg")
      assert_equal 1, links.length
      assert_equal({ :text => "File:Test.jpg", :url => "https://commons.wikimedia.org/wiki/File:Test.jpg?uselang=pt-BR", :type => :wikimedia_commons_link, :page => "File:Test.jpg" }, links[0])
    end

    links = TagParser.parse_value("foo", "Test")
    assert_not_equal :wikimedia_commons_link, links[0][:type]
  end

  def test_parse_value_email
    links = TagParser.parse_value("foo", "Test")
    assert_not_equal :email_link, links[0][:type]

    links = TagParser.parse_value("email", "123")
    assert_not_equal :email_link, links[0][:type]

    links = TagParser.parse_value("email", "Abc.example.com")
    assert_not_equal :email_link, links[0][:type]

    links = TagParser.parse_value("email", "a@b@c.com")
    assert_not_equal :email_link, links[0][:type]

    links = TagParser.parse_value("email", "just\"not\"right@example.com")
    assert_not_equal :email_link, links[0][:type]

    links = TagParser.parse_value("email", "123 abcdefg@space.com")
    assert_not_equal :email_link, links[0][:type]

    links = TagParser.parse_value("email", "test@ abc")
    assert_not_equal :email_link, links[0][:type]

    links = TagParser.parse_value("email", "using;semicolon@test.com")
    assert_not_equal :email_link, links[0][:type]

    links = TagParser.parse_value("email", "x@example.com")
    assert_equal 1, links.length
    assert_equal({ :text => "x@example.com", :url => "x@example.com", :type => :email_link, :email => "x@example.com" }, links[0])

    links = TagParser.parse_value("email", "other.email-with-hyphen@example.com")
    assert_equal 1, links.length
    assert_equal({ :text => "other.email-with-hyphen@example.com", :url => "other.email-with-hyphen@example.com", :type => :email_link, :email => "other.email-with-hyphen@example.com" }, links[0])

    links = TagParser.parse_value("email", "user.name+tag+sorting@example.com")
    assert_equal 1, links.length
    assert_equal({ :text => "user.name+tag+sorting@example.com", :url => "user.name+tag+sorting@example.com", :type => :email_link, :email => "user.name+tag+sorting@example.com" }, links[0])

    links = TagParser.parse_value("email", "dash-in@both-parts.com")
    assert_equal 1, links.length
    assert_equal({ :text => "dash-in@both-parts.com", :url => "dash-in@both-parts.com", :type => :email_link, :email => "dash-in@both-parts.com" }, links[0])

    links = TagParser.parse_value("email", "example@s.example")
    assert_equal 1, links.length
    assert_equal({ :text => "example@s.example", :url => "example@s.example", :type => :email_link, :email => "example@s.example" }, links[0])

    # Strips whitespace at ends
    links = TagParser.parse_value("email", " test@email.com ")
    assert_equal 1, links.length
    assert_equal({ :text => "test@email.com", :url => "test@email.com", :type => :email_link, :email => "test@email.com" }, links[0])

    links = TagParser.parse_value("contact:email", "example@example.com")
    assert_equal 1, links.length
    assert_equal({ :text => "example@example.com", :url => "example@example.com", :type => :email_link, :email => "example@example.com" }, links[0])

    links = TagParser.parse_value("maxweight:conditional", "none@agricultural")
    assert_not_equal :email_link, links[0][:type]
  end

  def test_parse_value_telephone
    links = TagParser.parse_value("foo", "Test")
    assert_not_equal :telephone_link, links[0][:type]

    links = TagParser.parse_value("phone", "+123")
    assert_not_equal :telephone_link, links[0][:type]

    links = TagParser.parse_value("phone", "123")
    assert_not_equal :telephone_link, links[0][:type]

    links = TagParser.parse_value("phone", "123 abcdefg")
    assert_not_equal :telephone_link, links[0][:type]

    links = TagParser.parse_value("phone", "+1234567890 abc")
    assert_not_equal :telephone_link, links[0][:type]

    # If multiple numbers are listed, all must be valid
    links = TagParser.parse_value("phone", "+1234567890; +223")
    assert_not_equal :telephone_link, links[0][:type]

    links = TagParser.parse_value("phone", "1234567890")
    assert_not_equal :telephone_link, links[0][:type]

    links = TagParser.parse_value("phone", "+1234567890")
    assert_equal 1, links.length
    assert_equal({ :text => "+1234567890", :url => "tel:+1234567890", :type => :telephone_link, :phone_number => "+1234567890" }, links[0])

    links = TagParser.parse_value("phone", "+1234-567-890")
    assert_equal 1, links.length
    assert_equal({ :text => "+1234-567-890", :url => "tel:+1234-567-890", :type => :telephone_link, :phone_number => "+1234-567-890" }, links[0])

    links = TagParser.parse_value("phone", "+1234/567/890")
    assert_equal 1, links.length
    assert_equal({ :text => "+1234/567/890", :url => "tel:+1234/567/890", :type => :telephone_link, :phone_number => "+1234/567/890" }, links[0])

    links = TagParser.parse_value("phone", "+1234.567.890")
    assert_equal 1, links.length
    assert_equal({ :text => "+1234.567.890", :url => "tel:+1234.567.890", :type => :telephone_link, :phone_number => "+1234.567.890" }, links[0])

    links = TagParser.parse_value("phone", "   +1234 567-890	")
    assert_equal 1, links.length
    assert_equal({ :text => "+1234 567-890", :url => "tel:+1234567-890", :type => :telephone_link, :phone_number => "+1234 567-890" }, links[0])

    links = TagParser.parse_value("phone", "+1 234-567-890")
    assert_equal 1, links.length
    assert_equal({ :text => "+1 234-567-890", :url => "tel:+1234-567-890", :type => :telephone_link, :phone_number => "+1 234-567-890" }, links[0])

    links = TagParser.parse_value("phone", "+1 (234) 567-890")
    assert_equal 1, links.length
    assert_equal({ :text => "+1 (234) 567-890", :url => "tel:+1(234)567-890", :type => :telephone_link, :phone_number => "+1 (234) 567-890" }, links[0])

    # Multiple valid phone numbers separated by ;
    links = TagParser.parse_value("phone", "+1234567890; +22334455667788")
    assert_equal 2, links.length
    assert_equal({ :text => "+1234567890", :url => "tel:+1234567890", :type => :telephone_link, :phone_number => "+1234567890" }, links[0])
    assert_equal({ :text => "+22334455667788", :url => "tel:+22334455667788", :type => :telephone_link, :phone_number => "+22334455667788" }, links[1])

    links = TagParser.parse_value("phone", "+1 (234) 567-890 ;  +22(33)4455.66.7788 ")
    assert_equal 2, links.length
    assert_equal({ :text => "+1 (234) 567-890", :url => "tel:+1(234)567-890", :type => :telephone_link, :phone_number => "+1 (234) 567-890" }, links[0])
    assert_equal({ :text => "+22(33)4455.66.7788", :url => "tel:+22(33)4455.66.7788", :type => :telephone_link, :phone_number => "+22(33)4455.66.7788" }, links[1])
  end

  def test_parse_value_colour
    # basic positive tests
    links = TagParser.parse_value("colour", "red")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "red" }, links[0])
    assert_equal({ :text => "red" }, links[1])

    links = TagParser.parse_value("colour", "Red")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "Red" }, links[0])
    assert_equal({ :text => "Red" }, links[1])

    links = TagParser.parse_value("colour", "darkRed")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "darkRed" }, links[0])
    assert_equal({ :text => "darkRed" }, links[1])

    links = TagParser.parse_value("colour", "#f00")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "#f00" }, links[0])
    assert_equal({ :text => "#f00" }, links[1])

    links = TagParser.parse_value("colour", "#fF0000")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "#fF0000" }, links[0])
    assert_equal({ :text => "#fF0000" }, links[1])

    # other tag variants:
    links = TagParser.parse_value("building:colour", "#f00")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "#f00" }, links[0])
    assert_equal({ :text => "#f00" }, links[1])

    links = TagParser.parse_value("ref:colour", "#f00")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "#f00" }, links[0])
    assert_equal({ :text => "#f00" }, links[1])

    links = TagParser.parse_value("int_ref:colour", "green")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "green" }, links[0])
    assert_equal({ :text => "green" }, links[1])

    links = TagParser.parse_value("roof:colour", "#f00")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "#f00" }, links[0])
    assert_equal({ :text => "#f00" }, links[1])

    links = TagParser.parse_value("seamark:beacon_lateral:colour", "#f00")
    assert_equal 2, links.length
    assert_equal({ :type => :html, :widget => :colour_preview, :colour_value => "#f00" }, links[0])
    assert_equal({ :text => "#f00" }, links[1])

    # negative tests:
    links = TagParser.parse_value("colour", "   ")
    assert_not_equal 2, links.length

    # ignore US spelling variant
    links = TagParser.parse_value("color", "red")
    assert_not_equal 2, links.length

    # irrelevant tag names
    links = TagParser.parse_value("building", "red")
    assert_not_equal 2, links.length

    links = TagParser.parse_value("ref:colour_no", "red")
    assert_not_equal 2, links.length

    links = TagParser.parse_value("ref:colour-bg", "red")
    assert_not_equal 2, links.length

    links = TagParser.parse_value("int_ref", "red")
    assert_not_equal 2, links.length

    # invalid hex codes
    links = TagParser.parse_value("colour", "#")
    assert_not_equal 2, links.length

    links = TagParser.parse_value("colour", "#ff")
    assert_not_equal 2, links.length

    links = TagParser.parse_value("colour", "#ffff")
    assert_not_equal 2, links.length

    links = TagParser.parse_value("colour", "#fffffff")
    assert_not_equal 2, links.length

    links = TagParser.parse_value("colour", "#ggg")
    assert_not_equal 2, links.length

    links = TagParser.parse_value("colour", "#ff 00 00")
    assert_not_equal 2, links.length

    # invalid w3c color names:
    links = TagParser.parse_value("colour", "r")
    assert_not_equal 2, links.length

    links = TagParser.parse_value("colour", "ffffff")
    assert_not_equal 2, links.length

    links = TagParser.parse_value("colour", "f00")
    assert_not_equal 2, links.length

    links = TagParser.parse_value("colour", "xxxred")
    assert_not_equal 2, links.length

    links = TagParser.parse_value("colour", "dark red")
    assert_not_equal 2, links.length

    links = TagParser.parse_value("colour", "dark_red")
    assert_not_equal 2, links.length

    links = TagParser.parse_value("colour", "ADarkDummyLongColourNameWithAPurpleUndertone")
    assert_not_equal 2, links.length
  end

  def test_parse_value_other
    links = TagParser.parse_value("website", "https://example.com/page")
    assert_nil links[0][:url]

    links = TagParser.parse_value("nonexistent_key", "SomeValue")
    assert_nil links[0][:url]

    links = TagParser.parse_value("mapillary", "123")
    assert_equal "https://www.mapillary.com/app/?pKey=123", links[0][:url]

    links = TagParser.parse_value("hashtags", "#maproulette")
    assert_equal "https://resultmaps.neis-one.org/osm-changesets?comment=maproulette", links[0][:url]
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
