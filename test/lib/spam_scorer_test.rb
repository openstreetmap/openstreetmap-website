# frozen_string_literal: true

require "test_helper"

class SpamScorerTest < ActiveSupport::TestCase
  def test_html_spam_score
    r = RichText.new("html", "foo <a href='http://example.com/'>bar</a> baz")
    scorer = SpamScorer.new(r)
    assert_equal 55, scorer.score.round
  end

  def test_markdown_spam_score
    r = RichText.new("markdown", "foo [bar](http://example.com/) baz")
    scorer = SpamScorer.new(r)
    assert_equal 50, scorer.score.round
  end

  def test_text_spam_score
    r = RichText.new("text", "foo http://example.com/ bar")
    scorer = SpamScorer.new(r)
    assert_equal 141, scorer.score.round
  end
end
