# frozen_string_literal: true

require "test_helper"

class ShareButtonsHelperTest < ActionView::TestCase
  include ShareButtonsHelper

  def test_share_buttons
    buttons = share_buttons(:title => "Diary Entry Title", :url => "https://osm.example.com/some/diary/entry")
    buttons_dom = Rails::Dom::Testing.html_document_fragment.parse(buttons)

    SHARE_BUTTONS_CONFIG.each do |icon|
      assert_dom buttons_dom, "div:has(a i.bi.bi-#{icon[:icon] || icon[:site]})", :count => 1 do
        assert_dom "a[href*='Diary%20Entry%20Title']"
        assert_dom "a[href*='https%3A%2F%2Fosm.example.com%2Fsome%2Fdiary%2Fentry']"
      end
    end
    assert_dom buttons_dom, "a[data-share-type='native']"
    assert_dom buttons_dom, "a[data-share-type='email'][href='mailto:?subject=Diary%20Entry%20Title&body=https%3A%2F%2Fosm.example.com%2Fsome%2Fdiary%2Fentry']"
  end
end
