require "test_helper"

class SocialShareButtonHelperTest < ActionView::TestCase
  include SocialShareButtonHelper

  def test_social_share_buttons
    buttons = social_share_buttons(:title => "Test Title", :url => "https://example.com")
    buttons_dom = Rails::Dom::Testing.html_document_fragment.parse(buttons)

    SOCIAL_SHARE_CONFIG.each_value do |icon|
      assert_dom buttons_dom, "div:has(a img[src='/images/#{icon}'])", :count => 1 do
        assert_dom "a[href*='Test%20Title']"
        assert_dom "a[href*='https%3A%2F%2Fexample.com']"
      end
    end
  end

  def test_generate_share_url_email
    url = generate_share_url(:email, "Diary Entry Title", "https://osm.example.com/some/diary/entry")
    assert_equal "mailto:?subject=Diary%20Entry%20Title&body=https%3A%2F%2Fosm.example.com%2Fsome%2Fdiary%2Fentry", url
  end
end
