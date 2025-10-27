# frozen_string_literal: true

require "test_helper"

class Tag2linkTest < ActiveSupport::TestCase
  def test_link_returns_nil_for_full_url
    assert_nil Tag2link.link("website", "https://example.com/page")
  end

  def test_link_returns_nil_for_unknown_key
    assert_nil Tag2link.link("nonexistent_key", "SomeValue")
  end

  def test_link_returns_proper_url_for_known_key
    url = Tag2link.link("wikidata", "Q936")
    assert_equal "https://www.wikidata.org/entity/Q936", url
  end
end
