require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  fixtures :users, :user_roles

  def setup
    I18n.locale = "en"
  end

  def test_linkify
    %w(http://example.com/test ftp://example.com/test https://example.com/test).each do |link|
      text = "Test #{link} is made into a link"

      html = linkify(text)
      assert_equal false, html.html_safe?
      assert_dom_equal "Test <a href=\"#{link}\" rel=\"nofollow\">#{link}</a> is made into a link", html

      html = linkify(text.html_safe)
      assert_equal true, html.html_safe?
      assert_dom_equal "Test <a href=\"#{link}\" rel=\"nofollow\">#{link}</a> is made into a link", html
    end

    %w(test@example.com mailto:test@example.com).each do |link|
      text = "Test #{link} is not made into a link"

      html = linkify(text)
      assert_equal false, html.html_safe?
      assert_dom_equal text, html

      html = linkify(text.html_safe)
      assert_equal true, html.html_safe?
      assert_dom_equal text, html
    end
  end

  def test_rss_link_to
    link = rss_link_to(:controller => :diary_entry, :action => :rss)
    assert_dom_equal "<a class=\"rsssmall\" href=\"/diary/rss\"><img alt=\"Rss\" border=\"0\" height=\"16\" src=\"/images/RSS.png\" width=\"16\" /></a>", link
  end

  def test_atom_link_to
    link = atom_link_to(:controller => :changeset, :action => :feed)
    assert_dom_equal "<a class=\"rsssmall\" href=\"/history/feed\"><img alt=\"Rss\" border=\"0\" height=\"16\" src=\"/images/RSS.png\" width=\"16\" /></a>", link
  end

  def test_style_rules
    @user = nil

    css = style_rules
    assert_match /\.hidden /, css
    assert_match /\.hide_unless_logged_in /, css
    assert_no_match /\.hide_if_logged_in /, css
    assert_no_match /\.hide_if_user_/, css
    assert_no_match /\.show_if_user_/, css
    assert_match /\.hide_unless_administrator /, css
    assert_match /\.hide_unless_moderator /, css

    @user = users(:normal_user)

    css = style_rules
    assert_match /\.hidden /, css
    assert_no_match /\.hide_unless_logged_in /, css
    assert_match /\.hide_if_logged_in /, css
    assert_match /\.hide_if_user_1 /, css
    assert_match /\.show_if_user_1 /, css
    assert_match /\.hide_unless_administrator /, css
    assert_match /\.hide_unless_moderator /, css

    @user = users(:moderator_user)

    css = style_rules
    assert_match /\.hidden /, css
    assert_no_match /\.hide_unless_logged_in /, css
    assert_match /\.hide_if_logged_in /, css
    assert_match /\.hide_if_user_5 /, css
    assert_match /\.show_if_user_5 /, css
    assert_match /\.hide_unless_administrator /, css
    assert_no_match /\.hide_unless_moderator /, css

    @user = users(:administrator_user)

    css = style_rules
    assert_match /\.hidden /, css
    assert_no_match /\.hide_unless_logged_in /, css
    assert_match /\.hide_if_logged_in /, css
    assert_match /\.hide_if_user_6 /, css
    assert_match /\.show_if_user_6 /, css
    assert_no_match /\.hide_unless_administrator /, css
    assert_match /\.hide_unless_moderator /, css
  end

  def test_if_logged_in
    html = if_logged_in { "Test 1" }
    assert_dom_equal "<div class=\"hide_unless_logged_in\">Test 1</div>", html

    html = if_logged_in(:span) { "Test 2" }
    assert_dom_equal "<span class=\"hide_unless_logged_in\">Test 2</span>", html
  end

  def test_if_not_logged_in
    html = if_not_logged_in { "Test 1" }
    assert_dom_equal "<div class=\"hide_if_logged_in\">Test 1</div>", html

    html = if_not_logged_in(:span) { "Test 2" }
    assert_dom_equal "<span class=\"hide_if_logged_in\">Test 2</span>", html
  end

  def test_if_user
    html = if_user(users(:normal_user)) { "Test 1" }
    assert_dom_equal "<div class=\"hidden show_if_user_1\">Test 1</div>", html

    html = if_user(users(:normal_user), :span) { "Test 2" }
    assert_dom_equal "<span class=\"hidden show_if_user_1\">Test 2</span>", html

    html = if_user(nil) { "Test 3" }
    assert_nil html

    html = if_user(nil, :span) { "Test 4" }
    assert_nil html
  end

  def test_unless_user
    html = unless_user(users(:normal_user)) { "Test 1" }
    assert_dom_equal "<div class=\"hide_if_user_1\">Test 1</div>", html

    html = unless_user(users(:normal_user), :span) { "Test 2" }
    assert_dom_equal "<span class=\"hide_if_user_1\">Test 2</span>", html

    html = unless_user(nil) { "Test 3" }
    assert_dom_equal "<div>Test 3</div>", html

    html = unless_user(nil, :span) { "Test 4" }
    assert_dom_equal "<span>Test 4</span>", html
  end

  def test_if_administrator
    html = if_administrator { "Test 1" }
    assert_dom_equal "<div class=\"hide_unless_administrator\">Test 1</div>", html

    html = if_administrator(:span) { "Test 2" }
    assert_dom_equal "<span class=\"hide_unless_administrator\">Test 2</span>", html
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
    assert_match /^<span title=" *5 March 2014 at 18:58">.*<\/span>$/, date

    date = friendly_date(Time.now - 1.hour)
    assert_match /^<span title=".*">about 1 hour<\/span>$/, date

    date = friendly_date(Time.now - 2.days)
    assert_match /^<span title=".*">2 days<\/span>$/, date

    date = friendly_date(Time.now - 3.weeks)
    assert_match /^<span title=".*">21 days<\/span>$/, date

    date = friendly_date(Time.now - 4.months)
    assert_match /^<span title=".*">4 months<\/span>$/, date
  end

  def test_body_class
  end

  def test_current_page_class
  end
end
