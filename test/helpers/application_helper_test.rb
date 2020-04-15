require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  attr_accessor :current_user

  def setup
    I18n.locale = "en"
  end

  def teardown
    I18n.locale = "en"
  end

  def test_linkify
    %w[http://example.com/test ftp://example.com/test https://example.com/test].each do |link|
      text = "Test #{link} is <b>made</b> into a link"

      html = linkify(text)
      assert html.html_safe?
      assert_dom_equal "Test <a href=\"#{link}\" rel=\"nofollow\">#{link}</a> is &lt;b&gt;made&lt;/b&gt; into a link", html

      html = linkify(text.html_safe)
      assert html.html_safe?
      assert_dom_equal "Test <a href=\"#{link}\" rel=\"nofollow\">#{link}</a> is <b>made</b> into a link", html
    end

    %w[test@example.com mailto:test@example.com].each do |link|
      text = "Test #{link} is not <b>made</b> into a link"

      html = linkify(text)
      assert html.html_safe?
      assert_dom_equal "Test #{link} is not &lt;b&gt;made&lt;/b&gt; into a link", html

      html = linkify(text.html_safe)
      assert html.html_safe?
      assert_dom_equal "Test #{link} is not <b>made</b> into a link", html
    end
  end

  def test_rss_link_to
    link = rss_link_to(:controller => :diary_entries, :action => :rss)
    assert_dom_equal "<a class=\"rsssmall\" href=\"/diary/rss\"><img border=\"0\" height=\"16\" src=\"/images/RSS.png\" width=\"16\" /></a>", link
  end

  def test_atom_link_to
    link = atom_link_to(:controller => :changesets, :action => :feed)
    assert_dom_equal "<a class=\"rsssmall\" href=\"/history/feed\"><img border=\"0\" height=\"16\" src=\"/images/RSS.png\" width=\"16\" /></a>", link
  end

  def test_richtext_area
    html = richtext_area(:message, :body, :cols => 40, :rows => 20)
    assert_not_nil html
  end

  def test_dir
    assert_equal "ltr", dir

    params[:dir] = "rtl"
    assert_equal "rtl", dir
    params.delete(:dir)

    I18n.locale = "he"

    assert_equal "rtl", dir

    params[:dir] = "ltr"
    assert_equal "ltr", dir
    params.delete(:dir)
  end

  def test_friendly_date
    date = friendly_date(Time.new(2014, 3, 5, 18, 58, 23))
    assert_match %r{^<span title=" *5 March 2014 at 18:58">.*</span>$}, date

    date = friendly_date(Time.now - 1.hour)
    assert_match %r{^<span title=".*">about 1 hour</span>$}, date

    date = friendly_date(Time.now - 2.days)
    assert_match %r{^<span title=".*">2 days</span>$}, date

    date = friendly_date(Time.now - 3.weeks)
    assert_match %r{^<span title=".*">21 days</span>$}, date

    date = friendly_date(Time.now - 4.months)
    assert_match %r{^<span title=".*">4 months</span>$}, date
  end

  def test_body_class; end

  def test_current_page_class; end
end
