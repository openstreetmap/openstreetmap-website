# coding: utf-8
require "test_helper"

class TitleHelperTest < ActionView::TestCase
  def test_set_title
    set_title
    assert_equal "OpenStreetMap", response.header["X-Page-Title"]
    assert_nil @title

    set_title(nil)
    assert_equal "OpenStreetMap", response.header["X-Page-Title"]
    assert_nil @title

    set_title("Test Title")
    assert_equal "OpenStreetMap%20%7C%20Test%20Title", response.header["X-Page-Title"]
    assert_equal "Test Title", @title

    set_title("Test & Title")
    assert_equal "OpenStreetMap%20%7C%20Test%20&%20Title", response.header["X-Page-Title"]
    assert_equal "Test & Title", @title

    set_title("Tést & Tïtlè")
    assert_equal "OpenStreetMap%20%7C%20T%C3%A9st%20&%20T%C3%AFtl%C3%A8", response.header["X-Page-Title"]
    assert_equal "Tést & Tïtlè", @title
  end
end
