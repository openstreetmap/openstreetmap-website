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

    r = RichText.new("html", "foo <a rel='junk me trash' href='http://example.com/'>bar</a> baz")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='http://example.com/']", 1
      assert_select "a[rel='me nofollow noopener noreferrer']", 1
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

    r = RichText.new("markdown", "foo <a rel='junk me trash' href='http://example.com/'>bar</a>) baz")
    assert_html r do
      assert_select "a", 1
      assert_select "a[href='http://example.com/']", 1
      assert_select "a[rel='me nofollow noopener noreferrer']", 1
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

  def test_markdown_table_alignment
    # Ensure that kramdown table alignment styles are converted to bootstrap classes
    markdown_table = <<~MARKDOWN
      | foo  | bar |
      |:----:|----:|
      |center|right|
    MARKDOWN
    r = RichText.new("markdown", markdown_table)
    assert_html r do
      assert_select "td[style='text-align:center']", false
      assert_select "td[class='text-center']", true
      assert_select "td[style='text-align:right']", false
      assert_select "td[class='text-end']", true
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

  def test_text_to_html_linkify
    with_settings(:linkify_hosts => ["replace-me.example.com"], :linkify_hosts_replacement => "repl.example.com") do
      r = RichText.new("text", "foo http://example.com/ bar")
      assert_html r do
        assert_dom "a", :count => 1, :text => "http://example.com/" do
          assert_dom "> @href", "http://example.com/"
          assert_dom "> @rel", "nofollow noopener noreferrer"
        end
      end
    end
  end

  def test_text_to_html_linkify_replace
    with_settings(:linkify_hosts => ["replace-me.example.com"], :linkify_hosts_replacement => "repl.example.com") do
      r = RichText.new("text", "foo https://replace-me.example.com/some/path?query=te<st&limit=20>10#result12 bar")
      assert_html r do
        assert_dom "a", :count => 1, :text => "repl.example.com/some/path?query=te<st&limit=20>10#result12" do
          assert_dom "> @href", "https://replace-me.example.com/some/path?query=te<st&limit=20>10#result12"
          assert_dom "> @rel", "nofollow noopener noreferrer"
        end
      end
    end
  end

  def test_text_to_html_linkify_replace_other_scheme
    with_settings(:linkify_hosts => ["replace-me.example.com"], :linkify_hosts_replacement => "repl.example.com") do
      r = RichText.new("text", "foo ftp://replace-me.example.com/some/path?query=te<st&limit=20>10#result12 bar")
      assert_html r do
        assert_dom "a", :count => 1, :text => "ftp://replace-me.example.com/some/path?query=te<st&limit=20>10#result12" do
          assert_dom "> @href", "ftp://replace-me.example.com/some/path?query=te<st&limit=20>10#result12"
          assert_dom "> @rel", "nofollow noopener noreferrer"
        end
      end
    end
  end

  def test_text_to_html_linkify_replace_undefined
    with_settings(:linkify_hosts => ["replace-me.example.com"], :linkify_hosts_replacement => nil) do
      r = RichText.new("text", "foo https://replace-me.example.com/some/path?query=te<st&limit=20>10#result12 bar")
      assert_html r do
        assert_dom "a", :count => 1, :text => "https://replace-me.example.com/some/path?query=te<st&limit=20>10#result12" do
          assert_dom "> @href", "https://replace-me.example.com/some/path?query=te<st&limit=20>10#result12"
          assert_dom "> @rel", "nofollow noopener noreferrer"
        end
      end
    end
  end

  def test_text_to_html_linkify_wiki_replace_prefix
    with_settings(:linkify_wiki_hosts => ["replace-me-wiki.example.com"], :linkify_wiki_hosts_replacement => "wiki.example.com",
                  :linkify_wiki_optional_path_prefix => "^/wiki(?=/[A-Z])") do
      r = RichText.new("text", "foo https://replace-me-wiki.example.com/wiki/Tag:surface%3Dmetal bar")
      assert_html r do
        assert_dom "a", :count => 1, :text => "wiki.example.com/Tag:surface%3Dmetal" do
          assert_dom "> @href", "https://replace-me-wiki.example.com/wiki/Tag:surface%3Dmetal"
          assert_dom "> @rel", "nofollow noopener noreferrer"
        end
      end
    end
  end

  def test_text_to_html_linkify_wiki_replace_prefix_undefined
    with_settings(:linkify_wiki_hosts => ["replace-me-wiki.example.com"], :linkify_wiki_hosts_replacement => "wiki.example.com",
                  :linkify_wiki_optional_path_prefix => nil) do
      r = RichText.new("text", "foo https://replace-me-wiki.example.com/wiki/Tag:surface%3Dmetal bar")
      assert_html r do
        assert_dom "a", :count => 1, :text => "wiki.example.com/wiki/Tag:surface%3Dmetal" do
          assert_dom "> @href", "https://replace-me-wiki.example.com/wiki/Tag:surface%3Dmetal"
          assert_dom "> @rel", "nofollow noopener noreferrer"
        end
      end
    end
  end

  def test_text_to_html_linkify_wiki_replace_undefined_prefix
    with_settings(:linkify_wiki_hosts => ["replace-me-wiki.example.com"], :linkify_wiki_hosts_replacement => nil,
                  :linkify_wiki_optional_path_prefix => "^/wiki(?=/[A-Z])") do
      r = RichText.new("text", "foo https://replace-me-wiki.example.com/wiki/Tag:surface%3Dmetal bar")
      assert_html r do
        assert_dom "a", :count => 1, :text => "https://replace-me-wiki.example.com/Tag:surface%3Dmetal" do
          assert_dom "> @href", "https://replace-me-wiki.example.com/wiki/Tag:surface%3Dmetal"
          assert_dom "> @rel", "nofollow noopener noreferrer"
        end
      end
    end
  end

  def test_text_to_html_linkify_wiki_replace_prefix_no_match
    with_settings(:linkify_wiki_hosts => ["replace-me-wiki.example.com"], :linkify_wiki_hosts_replacement => "wiki.example.com",
                  :linkify_wiki_optional_path_prefix => "^/wiki(?=/[A-Z])") do
      r = RichText.new("text", "foo https://replace-me-wiki.example.com/wiki/w bar")
      assert_html r do
        assert_dom "a", :count => 1, :text => "wiki.example.com/wiki/w" do
          assert_dom "> @href", "https://replace-me-wiki.example.com/wiki/w"
          assert_dom "> @rel", "nofollow noopener noreferrer"
        end
      end
    end
  end

  def test_text_to_html_email
    r = RichText.new("text", "foo example@example.com bar")
    assert_html r do
      assert_select "a", 0
    end
  end

  def test_text_to_html_escape
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

  def test_text_no_opengraph_properties
    r = RichText.new("text", "foo https://example.com/ bar")
    assert_nil r.image
    assert_nil r.image_alt
    assert_nil r.description
  end

  def test_html_no_opengraph_properties
    r = RichText.new("html", "foo <a href='https://example.com/'>bar</a> baz")
    assert_nil r.image
    assert_nil r.image_alt
    assert_nil r.description
  end

  def test_markdown_no_image
    r = RichText.new("markdown", "foo [bar](https://example.com/) baz")
    assert_nil r.image
    assert_nil r.image_alt
  end

  def test_markdown_image
    r = RichText.new("markdown", "foo ![bar](https://example.com/image.jpg) baz")
    assert_equal "https://example.com/image.jpg", r.image
    assert_equal "bar", r.image_alt
  end

  def test_markdown_first_image
    r = RichText.new("markdown", "foo ![bar1](https://example.com/image1.jpg) baz\nfoo ![bar2](https://example.com/image2.jpg) baz")
    assert_equal "https://example.com/image1.jpg", r.image
    assert_equal "bar1", r.image_alt
  end

  def test_markdown_image_with_empty_src
    r = RichText.new("markdown", "![invalid]()")
    assert_nil r.image
    assert_nil r.image_alt
  end

  def test_markdown_skip_image_with_empty_src
    r = RichText.new("markdown", "![invalid]() ![valid](https://example.com/valid.gif)")
    assert_equal "https://example.com/valid.gif", r.image
    assert_equal "valid", r.image_alt
  end

  def test_markdown_html_image
    r = RichText.new("markdown", "<img src='https://example.com/img_element.png' alt='alt text here'>")
    assert_equal "https://example.com/img_element.png", r.image
    assert_equal "alt text here", r.image_alt
  end

  def test_markdown_html_image_without_alt
    r = RichText.new("markdown", "<img src='https://example.com/img_element.png'>")
    assert_equal "https://example.com/img_element.png", r.image
    assert_nil r.image_alt
  end

  def test_markdown_html_image_with_empty_src
    r = RichText.new("markdown", "<img src='' alt='forgot src'>")
    assert_nil r.image
    assert_nil r.image_alt
  end

  def test_markdown_skip_html_image_with_empty_src
    r = RichText.new("markdown", "<img src='' alt='forgot src'> <img src='https://example.com/next_img_element.png' alt='have src'>")
    assert_equal "https://example.com/next_img_element.png", r.image
    assert_equal "have src", r.image_alt
  end

  def test_markdown_html_image_without_src
    r = RichText.new("markdown", "<img alt='totally forgot src'>")
    assert_nil r.image
    assert_nil r.image_alt
  end

  def test_markdown_skip_html_image_without_src
    r = RichText.new("markdown", "<img alt='totally forgot src'> <img src='https://example.com/next_img_element.png' alt='have src'>")
    assert_equal "https://example.com/next_img_element.png", r.image
    assert_equal "have src", r.image_alt
  end

  def test_markdown_no_description
    r = RichText.new("markdown", "#Nope")
    assert_nil r.description
  end

  def test_markdown_description
    r = RichText.new("markdown", "This is an article about something.")
    assert_equal "This is an article about something.", r.description
  end

  def test_markdown_description_after_heading
    r = RichText.new("markdown", "#Heading\n\nHere starts the text.")
    assert_equal "Here starts the text.", r.description
  end

  def test_markdown_description_after_image
    r = RichText.new("markdown", "![bar](https://example.com/image.jpg)\n\nThis is below the image.")
    assert_equal "This is below the image.", r.description
  end

  def test_markdown_description_only_first_paragraph
    r = RichText.new("markdown", "This thing.\n\nMaybe also that thing.")
    assert_equal "This thing.", r.description
  end

  def test_markdown_description_elements
    r = RichText.new("markdown", "*Something* **important** [here](https://example.com/).")
    assert_equal "Something important here.", r.description
  end

  def test_markdown_html_description
    r = RichText.new("markdown", "<p>Can use HTML tags.</p>")
    assert_equal "Can use HTML tags.", r.description
  end

  def test_markdown_description_max_length
    m = RichText::DESCRIPTION_MAX_LENGTH
    o = 3 # "...".length

    r = RichText.new("markdown", "x" * m)
    assert_equal "x" * m, r.description

    r = RichText.new("markdown", "y" * (m + 1))
    assert_equal "#{'y' * (m - o)}...", r.description

    r = RichText.new("markdown", "*zzzzzzzzz*z" * ((m + 1) / 10.0).ceil)
    assert_equal "#{'z' * (m - o)}...", r.description
  end

  def test_markdown_description_word_break_threshold_length
    m = RichText::DESCRIPTION_MAX_LENGTH
    t = RichText::DESCRIPTION_WORD_BREAK_THRESHOLD_LENGTH
    o = 3 # "...".length

    r = RichText.new("markdown", "#{'x' * (t - o - 1)} #{'y' * (m - (t - o - 1) - 1)}")
    assert_equal "#{'x' * (t - o - 1)} #{'y' * (m - (t - o - 1) - 1)}", r.description

    r = RichText.new("markdown", "#{'x' * (t - o - 1)} #{'y' * (m - (t - o - 1))}")
    assert_equal "#{'x' * (t - o - 1)} #{'y' * (m - (t - o - 1) - 4)}...", r.description

    r = RichText.new("markdown", "#{'x' * (t - o)} #{'y' * (m - (t - o) - 1)}")
    assert_equal "#{'x' * (t - o)} #{'y' * (m - (t - o) - 1)}", r.description

    r = RichText.new("markdown", "#{'x' * (t - o)} #{'y' * (m - (t - o))}")
    assert_equal "#{'x' * (t - o)}...", r.description
  end

  def test_markdown_description_word_break_multiple_spaces
    m = RichText::DESCRIPTION_MAX_LENGTH
    t = RichText::DESCRIPTION_WORD_BREAK_THRESHOLD_LENGTH
    o = 3 # "...".length

    r = RichText.new("markdown", "#{'x' * (t - o)}  #{'y' * (m - (t - o - 1))}")
    assert_equal "#{'x' * (t - o)}...", r.description
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
