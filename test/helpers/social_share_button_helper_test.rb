require "test_helper"

class SocialShareButtonHelperTest < ActionView::TestCase
  include SocialShareButtonHelper

  def test_social_share_buttons
    buttons = social_share_buttons(:title => "Test Title", :url => "https://example.com")
    buttons_dom = Rails::Dom::Testing.html_document_fragment.parse(buttons)

    SOCIAL_SHARE_CONFIG.each_value do |icon|
      assert_dom buttons_dom, "div:has(a img[src='/images/#{icon}'])", :count => 1 do
        assert_dom "a[href*='Test+Title']"
        assert_dom "a[href*='https%3A%2F%2Fexample.com']"
      end
    end
  end
end
