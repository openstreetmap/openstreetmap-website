
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
    assert_equal "Test%20Title%20%7C%20OpenStreetMap", response.header["X-Page-Title"]
    assert_equal "Test Title", @title

    set_title("Test & Title")
    assert_equal "Test%20%26%20Title%20%7C%20OpenStreetMap", response.header["X-Page-Title"]
    assert_equal "Test & Title", @title

    set_title("Tést & Tïtlè")
    assert_equal "T%C3%A9st%20%26%20T%C3%AFtl%C3%A8%20%7C%20OpenStreetMap", response.header["X-Page-Title"]
    assert_equal "Tést & Tïtlè", @title
  end
end
