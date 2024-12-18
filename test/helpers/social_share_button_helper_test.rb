require "test_helper"

class SocialShareButtonHelperTest < ActionView::TestCase
  include SocialShareButtonHelper

  def setup
    @options = {
      :title => "Test Title",
      :url => "https://example.com",
      :desc => "Test Description",
      :via => "testuser"
    }
  end

  def test_social_share_buttons
    result = social_share_buttons(@options)
    assert_includes result, "email"
    assert_includes result, "bluesky"
    assert_includes result, "facebook"
    assert_includes result, "linkedin"
    assert_includes result, "mastodon"
    assert_includes result, "telegram"
    assert_includes result, "x"
  end
end
