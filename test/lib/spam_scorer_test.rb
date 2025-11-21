# frozen_string_literal: true

require "test_helper"

class SpamScorerTest < ActiveSupport::TestCase
  def test_html_spam_score
    r = RichText.new("html", "foo <a href='http://example.com/'>bar</a> baz")
    scorer = SpamScorer.new_from_rich_text(r)
    assert_equal 55, scorer.score.round
  end

  def test_markdown_spam_score
    r = RichText.new("markdown", "foo [bar](http://example.com/) baz")
    scorer = SpamScorer.new_from_rich_text(r)
    assert_equal 50, scorer.score.round
  end

  def test_text_spam_score
    r = RichText.new("text", "foo http://example.com/ bar")
    scorer = SpamScorer.new_from_rich_text(r)
    assert_equal 141, scorer.score.round
  end

  def test_user_spam_score
    user = build(:user, :description => "foo [bar](http://example.com/) baz")
    scorer = SpamScorer.new_from_user(user)
    assert_equal 12, scorer.score
  end

  def test_spammy_phrases
    r = RichText.new("markdown", "Business Description: totally legit beesknees. Additional Keywords: apiary joints")
    scorer = SpamScorer.new_from_rich_text(r)
    assert_equal 80, scorer.score.round
  end
end
