require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  attr_accessor :current_user

  def test_linkify
    %w[http://example.com/test ftp://example.com/test https://example.com/test].each do |link|
      text = "Test #{link} is <b>made</b> into a link"

      html = linkify(text)
      assert_predicate html, :html_safe?
      assert_dom_equal "Test <a href=\"#{link}\" rel=\"nofollow\">#{link}</a> is &lt;b&gt;made&lt;/b&gt; into a link", html

      html = linkify(text.html_safe)
      assert_predicate html, :html_safe?
      assert_dom_equal "Test <a href=\"#{link}\" rel=\"nofollow\">#{link}</a> is <b>made</b> into a link", html
    end

    %w[test@example.com mailto:test@example.com].each do |link|
      text = "Test #{link} is not <b>made</b> into a link"

      html = linkify(text)
      assert_predicate html, :html_safe?
      assert_dom_equal "Test #{link} is not &lt;b&gt;made&lt;/b&gt; into a link", html

      html = linkify(text.html_safe)
      assert_predicate html, :html_safe?
      assert_dom_equal "Test #{link} is not <b>made</b> into a link", html
    end
  end

  def test_rss_link_to
    link = rss_link_to(:controller => :diary_entries, :action => :rss)
    assert_dom_equal "<a href=\"/diary/rss\"><img height=\"16\" src=\"/images/RSS.png\" width=\"16\" class=\"align-text-bottom\" /></a>", link
  end

  def test_atom_link_to
    link = atom_link_to(:controller => :changesets, :action => :feed)
    assert_dom_equal "<a href=\"/history/feed\"><img height=\"16\" src=\"/images/RSS.png\" width=\"16\" class=\"align-text-bottom\" /></a>", link
  end

  def test_dir
    assert_equal "ltr", dir

    params[:dir] = "rtl"
    assert_equal "rtl", dir
    params.delete(:dir)

    I18n.with_locale "he" do
      assert_equal "rtl", dir

      params[:dir] = "ltr"
      assert_equal "ltr", dir
      params.delete(:dir)
    end
  end

  def test_friendly_date
    date = friendly_date(Time.utc(2014, 3, 5, 18, 58, 23))
    assert_match %r{^<time title=" *5 March 2014 at 18:58" datetime="2014-03-05T18:58:23Z">.*</time>$}, date

    date = friendly_date(Time.now.utc - 1.hour)
    assert_match %r{^<time title=".*">about 1 hour</time>$}, date

    date = friendly_date(Time.now.utc - 2.days)
    assert_match %r{^<time title=".*">2 days</time>$}, date

    date = friendly_date(Time.now.utc - 3.weeks)
    assert_match %r{^<time title=".*">21 days</time>$}, date

    date = friendly_date(Time.now.utc - 4.months)
    assert_match %r{^<time title=".*">4 months</time>$}, date
  end

  def test_friendly_date_ago
    date = friendly_date_ago(Time.utc(2014, 3, 5, 18, 58, 23))
    assert_match %r{^<time title=" *5 March 2014 at 18:58" datetime="2014-03-05T18:58:23Z">.*</time>$}, date

    date = friendly_date_ago(Time.now.utc - 1.hour)
    assert_match %r{^<time title=".*">about 1 hour ago</time>$}, date

    date = friendly_date_ago(Time.now.utc - 2.days)
    assert_match %r{^<time title=".*">2 days ago</time>$}, date

    date = friendly_date_ago(Time.now.utc - 3.weeks)
    assert_match %r{^<time title=".*">21 days ago</time>$}, date

    date = friendly_date_ago(Time.now.utc - 4.months)
    assert_match %r{^<time title=".*">4 months ago</time>$}, date
  end
end
