require "test_helper"

class RichTextTest < ActiveSupport::TestCase
  include Rails::Dom::Testing::Assertions::SelectorAssertions

  def test_html_to_html
    r = RichText.new("html", "foo http://example.com/ bar")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='http://example.com/']", 1
      assert_select "a[rel='nofollow noopener noreferrer']", 1
    end

    r = RichText.new("html", "foo <a href='http://example.com/'>bar</a> baz")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='http://example.com/']", 1
      assert_select "a[rel='nofollow noopener noreferrer']", 1
    end

    r = RichText.new("html", "foo example@example.com bar")
    assert_html r do
      assert_select "a", 0
    end

    r = RichText.new("html", "foo <a href='mailto:example@example.com'>bar</a> baz")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='mailto:example@example.com']", 1
      assert_select "a[rel='nofollow noopener noreferrer']", 1
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

    r = RichText.new("html", "<table><tr><td>column</td></tr></table>")
    assert_html r do
      assert_select "table[class='table table-sm w-auto']"
    end

    r = RichText.new("html", "<p class='btn btn-warning'>Click Me</p>")
    assert_html r do
      assert_select "p[class='btn btn-warning']", false
      assert_select "p", /^Click Me$/
    end

    r = RichText.new("html", "<p style='color:red'>Danger</p>")
    assert_html r do
      assert_select "p[style='color:red']", false
      assert_select "p", /^Danger$/
    end
  end

  def test_html_to_text
    r = RichText.new("html", "foo <a href='http://example.com/'>bar</a> baz")
    assert_equal "foo <a href='http://example.com/'>bar</a> baz", r.to_text
  end

  def test_html_spam_score
    r = RichText.new("html", "foo <a href='http://example.com/'>bar</a> baz")
    assert_equal 55, r.spam_score.round
  end

  def test_markdown_to_html
    r = RichText.new("markdown", "foo http://example.com/ bar")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='http://example.com/']", 1
      assert_select "a[rel='nofollow noopener noreferrer']", 1
    end

    r = RichText.new("markdown", "foo [bar](http://example.com/) baz")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='http://example.com/']", 1
      assert_select "a[rel='nofollow noopener noreferrer']", 1
    end

    r = RichText.new("markdown", "foo example@example.com bar")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='mailto:example@example.com']", 1
      assert_select "a[rel='nofollow noopener noreferrer']", 1
    end

    r = RichText.new("markdown", "foo [bar](mailto:example@example.com) bar")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='mailto:example@example.com']", 1
      assert_select "a[rel='nofollow noopener noreferrer']", 1
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

    r = RichText.new("markdown", "|column|column")
    assert_html r do
      assert_select "table[class='table table-sm w-auto']"
    end

    r = RichText.new("markdown", "Click Me\n{:.btn.btn-warning}")
    assert_html r do
      assert_select "p[class='btn btn-warning']", false
      assert_select "p", /^Click Me$/
    end

    r = RichText.new("markdown", "<p style='color:red'>Danger</p>")
    assert_html r do
      assert_select "p[style='color:red']", false
      assert_select "p", /^Danger$/
    end
  end

  def test_markdown_to_text
    r = RichText.new("markdown", "foo [bar](http://example.com/) baz")
    assert_equal "foo [bar](http://example.com/) baz", r.to_text
  end

  def test_markdown_spam_score
    r = RichText.new("markdown", "foo [bar](http://example.com/) baz")
    assert_equal 50, r.spam_score.round
  end

  def test_text_to_html
    r = RichText.new("text", "foo http://example.com/ bar")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='http://example.com/']", 1
      assert_select "a[rel='nofollow noopener noreferrer']", 1
    end

    r = RichText.new("text", "foo example@example.com bar")
    assert_html r do
      assert_select "a", 0
    end

    r = RichText.new("text", "foo < bar & baz > qux")
    assert_html r do
      assert_select "p", "foo < bar & baz > qux"
    end
  end

  def test_text_to_text
    r = RichText.new("text", "foo http://example.com/ bar")
    assert_equal "foo http://example.com/ bar", r.to_text
  end

  def test_text_spam_score
    r = RichText.new("text", "foo http://example.com/ bar")
    assert_equal 141, r.spam_score.round
  end

  private

  def assert_html(richtext, &block)
    html = richtext.to_html
    assert_predicate html, :html_safe?
    root = Nokogiri::HTML::DocumentFragment.parse(html)
    assert_select root, "*" do
      yield block
    end
  end
end
