require "test_helper"

class SocialShareButtonHelperTest < ActionView::TestCase
  include SocialShareButtonHelper

  def setup
    @options = {
      :allow_sites => %w[x facebook linkedin],
      :title => "Test Title",
      :url => "https://example.com",
      :desc => "Test Description",
      :via => "testuser"
    }
  end

  def test_social_share_buttons_with_valid_sites
    result = social_share_buttons(@options)
    assert_includes result, "x"
    assert_includes result, "facebook"
    assert_includes result, "linkedin"
  end

  def test_render_social_share_buttons_with_invalid_site
    @options[:allow_sites] << "invalid_site"
    result = social_share_buttons(@options)
    assert_not_includes result, "invalid_site"
  end

  def test_social_share_buttons_with_no_sites
    @options[:allow_sites] = []
    result = social_share_buttons(@options)
    SocialShareButtonHelper::SOCIAL_SHARE_CONFIG.each_key do |site|
      assert_includes result, site.to_s # Convert symbol to string
    end
  end
end
