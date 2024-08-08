require "test_helper"

class SocialShareButtonHelperTest < ActionView::TestCase
  include SocialShareButtonHelper
  include ApplicationHelper

  def setup
    @options = {
      :allow_sites => %w[twitter facebook linkedin],
      :title => "Test Title",
      :url => "https://example.com",
      :desc => "Test Description",
      :via => "testuser"
    }
  end

  def test_render_social_share_buttons_with_valid_sites
    result = render_social_share_buttons(@options)
    assert_includes result, "twitter"
    assert_includes result, "facebook"
    assert_includes result, "linkedin"
  end

  def test_render_social_share_buttons_with_invalid_site
    @options[:allow_sites] << "invalid_site"
    result = render_social_share_buttons(@options)
    assert_not_includes result, "invalid_site"
  end

  def test_render_social_share_buttons_with_no_sites
    @options[:allow_sites] = []
    result = render_social_share_buttons(@options)
    SocialShareButtonHelper::SOCIAL_SHARE_CONFIG.each_key do |site|
      assert_includes result, site
    end
  end

  def test_filter_allowed_sites
    valid_sites, invalid_sites = SocialShareButtonHelper.filter_allowed_sites(%w[twitter facebook invalid_site])
    assert_equal %w[twitter facebook], valid_sites
    assert_equal %w[invalid_site], invalid_sites
  end

  def test_icon_path
    assert_equal "social_icons/twitter.svg", SocialShareButtonHelper.icon_path("twitter")
    assert_equal "", SocialShareButtonHelper.icon_path("invalid_site")
  end
end
