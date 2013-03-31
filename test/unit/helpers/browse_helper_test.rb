require 'test_helper'
require 'action_view/test_case'

class BrowseHelperTest < ActionView::TestCase

  def setup
    @key = 'wikipedia'
    @language = 'zh-classical'
    @title = 'Test_method'
    @locale = "#{I18n.locale}"
  end
  
  def test_wikipedia_link_helper_when_key_is_nil
    key, value = nil, nil
    assert_equal nil, wikipedia_link(key, value)
  end

  def test_wikipedia_link_helper_when_key_is_wikipedia_value_is_simple_string
    key, value = @key, @title
    expected_hash = { url: "http://en.wikipedia.org/wiki/#{@title}?uselang=#{@locale}", title: @title }
    assert_equal expected_hash, wikipedia_link(key, value)
  end

  def test_wikipedia_link_helper_when_key_is_wikipedia_including_language_string
    key, value = "#{@key}:#{@language}", "#{@title}"
    expected_hash = { url: "http://#{@language}.wikipedia.org/wiki/#{@title}?uselang=#{@locale}", title: "#{@title}" }
    assert_equal expected_hash, wikipedia_link(key, value)
  end

  def test_wikipedia_link_helper_when_key_is_wikipedia_value_includes_language_string
    key, value = @key, "#{@language}:#{@title}"
    expected_hash = { url: "http://#{@language}.wikipedia.org/wiki/#{@language}:#{@title}?uselang=#{@locale}", title: "#{@language}:#{@title}" }
    assert_equal expected_hash, wikipedia_link(key, value)
  end

end
