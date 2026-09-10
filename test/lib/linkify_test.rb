# frozen_string_literal: true

require "test_helper"

class LinkifyTest < ActionView::TestCase
  def test_linkify
    %w[http://example.com/test ftp://example.com/test https://example.com/test].each do |link|
      text = "Test #{link} is <b>made</b> into a link"

      html = Linkify.call(text)
      assert_predicate html, :html_safe?
      assert_dom_equal "Test <a href=\"#{link}\" rel=\"nofollow noopener noreferrer\" dir=\"auto\">#{link}</a> is &lt;b&gt;made&lt;/b&gt; into a link", html

      html = Linkify.call(text.html_safe)
      assert_predicate html, :html_safe?
      assert_dom_equal "Test <a href=\"#{link}\" rel=\"nofollow noopener noreferrer\" dir=\"auto\">#{link}</a> is <b>made</b> into a link", html
    end

    %w[test@example.com mailto:test@example.com].each do |link|
      text = "Test #{link} is not <b>made</b> into a link"

      html = Linkify.call(text)
      assert_predicate html, :html_safe?
      assert_dom_equal "Test #{link} is not &lt;b&gt;made&lt;/b&gt; into a link", html

      html = Linkify.call(text.html_safe)
      assert_predicate html, :html_safe?
      assert_dom_equal "Test #{link} is not <b>made</b> into a link", html
    end
  end
end
