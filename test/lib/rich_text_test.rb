require 'test_helper'

class RichTextTest < ActiveSupport::TestCase
  include ActionDispatch::Assertions::SelectorAssertions

  def test_html_to_html
    r = RichText.new("html", "foo http://example.com/ bar")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='http://example.com/']", 1
      assert_select "a[rel='nofollow']", 1
    end

    r = RichText.new("html", "foo <a href='http://example.com/'>bar</a> baz")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='http://example.com/']", 1
      assert_select "a[rel='nofollow']", 1
    end

    r = RichText.new("html", "foo example@example.com bar")
    assert_html r do
      assert_select "a", 0
    end

    r = RichText.new("html", "foo <a href='mailto:example@example.com'>bar</a> baz")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='mailto:example@example.com']", 1
      assert_select "a[rel='nofollow']", 1
    end

    r = RichText.new("html", "foo <div>bar</div> baz")
    assert_html r do
      assert_select "div", false
      assert_select "p", /^foo *bar *baz$/
    end

    r = RichText.new("html", "foo <script>bar = 1;</script> baz")
    assert_html r do
      assert_select "script", false
      assert_select "p", /^foo *baz$/
    end

    r = RichText.new("html", "foo <style>div { display: none; }</style> baz")
    assert_html r do
      assert_select "style", false
      assert_select "p", /^foo *baz$/
    end
  end

  def test_markdown_to_html
    r = RichText.new("markdown", "foo http://example.com/ bar")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='http://example.com/']", 1
      assert_select "a[rel='nofollow']", 1
    end

    r = RichText.new("markdown", "foo [bar](http://example.com/) baz")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='http://example.com/']", 1
      assert_select "a[rel='nofollow']", 1
    end

    r = RichText.new("markdown", "foo example@example.com bar")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='mailto:example@example.com']", 1
      assert_select "a[rel='nofollow']", 1
    end

    r = RichText.new("markdown", "foo [bar](mailto:example@example.com) bar")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='mailto:example@example.com']", 1
      assert_select "a[rel='nofollow']", 1
    end

    r = RichText.new("markdown", "foo ![bar](http://example.com/example.png) bar")
    assert_html r do
      assert_select "img", 1
      assert_select "img[alt='bar']", 1
      assert_select "img[src='http://example.com/example.png']", 1
    end

    r = RichText.new("markdown", "# foo bar baz")
    assert_html r do
      assert_select "h1", "foo bar baz"
    end

    r = RichText.new("markdown", "## foo bar baz")
    assert_html r do
      assert_select "h2", "foo bar baz"
    end

    r = RichText.new("markdown", "### foo bar baz")
    assert_html r do
      assert_select "h3", "foo bar baz"
    end

    r = RichText.new("markdown", "* foo bar baz")
    assert_html r do
      assert_select "ul" do
        assert_select "li", "foo bar baz"
      end
    end

    r = RichText.new("markdown", "1. foo bar baz")
    assert_html r do
      assert_select "ol" do
        assert_select "li", "foo bar baz"
      end
    end

    r = RichText.new("markdown", "foo *bar* _baz_ qux")
    assert_html r do
      assert_select "em", "bar"
      assert_select "em", "baz"
    end

    r = RichText.new("markdown", "foo **bar** __baz__ qux")
    assert_html r do
      assert_select "strong", "bar"
      assert_select "strong", "baz"
    end

    r = RichText.new("markdown", "foo `bar` baz")
    assert_html r do
      assert_select "code", "bar"
    end

    r = RichText.new("markdown", "    foo bar baz")
    assert_html r do
      assert_select "pre", /^\s*foo bar baz\s*$/
    end
  end

  def test_text_to_html
    r = RichText.new("text", "foo http://example.com/ bar")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='http://example.com/']", 1
      assert_select "a[rel='nofollow']", 1
    end

    r = RichText.new("text", "foo example@example.com bar")
    assert_html r do
      assert_select "a", 0
    end

    r = RichText.new("text", "foo < bar & baz > qux")
    assert_html r do
      assert_select "p", "foo &lt; bar &amp; baz &gt; qux"
    end
  end

private

  def assert_html(richtext, &block)
    html = richtext.to_html
    assert html.html_safe?
    root = HTML::Document.new(richtext.to_html, false, true).root
    assert_select root, "*" do
      yield block
    end
  end
end
