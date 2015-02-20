require "test_helper"

class TitleHelperTest < ActionView::TestCase
  def test_set_title
    set_title(nil)
    assert_equal "OpenStreetMap", response.header["X-Page-Title"]
    assert_nil @title

    set_title("Test Title")
    assert_equal "OpenStreetMap | Test Title", response.header["X-Page-Title"]
    assert_equal "Test Title", @title

    set_title("Test & Title")
    assert_equal "OpenStreetMap | Test & Title", response.header["X-Page-Title"]
    assert_equal "Test & Title", @title
  end
end
