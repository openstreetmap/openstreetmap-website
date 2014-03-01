require 'test_helper'

class BrowseHelperTest < ActionView::TestCase
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
