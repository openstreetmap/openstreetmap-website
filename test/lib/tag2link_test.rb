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

  def test_link_strips_path_terminators
    url = Tag2link.link("hashtags", "#maproulette")
    assert_equal "https://resultmaps.neis-one.org/osm-changesets?comment=maproulette", url
  end

  def test_build_dict_rejects_deprecated_and_third_party
    data = [
      { "key" => "Key:example", "url" => "http://example.com/$1", "rank" => "deprecated", "source" => "osmwiki:P8" },
      { "key" => "Key:example2", "url" => "http://example2.com/$1", "rank" => "preferred", "source" => "wikidata:P3303" },
      { "key" => "Key:example3", "url" => "http://example3.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" }
    ]
    dict = Tag2link.build_dict(data)
    assert_not_includes dict, "example"
    assert_not_includes dict, "example2"
    assert_includes dict, "example3"
  end

  def test_build_dict_chooses_single_preferred_item
    data = [
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "normal", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" }
    ]
    dict = Tag2link.build_dict(data)
    assert_equal "http://example.com/$1", dict["example"]

    data = [
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example.com/$1", "rank" => "preferred", "source" => "wikidata:P1630" },
      { "key" => "Key:example", "url" => "http://example3.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" }
    ]
    dict = Tag2link.build_dict(data)
    assert_equal "http://example.com/$1", dict["example"]

    data = [
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" }
    ]
    dict = Tag2link.build_dict(data)
    assert_equal "http://example2.com/$1", dict["example"]
  end

  def test_build_dict_deduplicates_urls
    data = [
      { "key" => "Key:example", "url" => "http://example.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example.com/$1", "rank" => "normal", "source" => "wikidata:P1630" }
    ]
    dict = Tag2link.build_dict(data)
    assert_equal "http://example.com/$1", dict["example"]
  end

  def test_build_dict_rejects_multiple_equally_preferred_items
    data = [
      { "key" => "Key:example", "url" => "http://example1.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" }
    ]
    dict = Tag2link.build_dict(data)
    assert_not_includes dict, "example"

    data = [
      { "key" => "Key:example", "url" => "http://example1.com/$1", "rank" => "normal", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "normal", "source" => "osmwiki:P8" }
    ]
    dict = Tag2link.build_dict(data)
    assert_not_includes dict, "example"
  end

  def test_build_dict_chooses_osmwiki_when_both_have_single_preferred
    data = [
      { "key" => "Key:example", "url" => "http://example1.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "preferred", "source" => "wikidata:P1630" }
    ]
    dict = Tag2link.build_dict(data)
    assert_equal "http://example1.com/$1", dict["example"]

    data = [
      { "key" => "Key:example", "url" => "http://example1.com/$1", "rank" => "normal", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "normal", "source" => "wikidata:P1630" }
    ]
    dict = Tag2link.build_dict(data)
    assert_equal "http://example1.com/$1", dict["example"]
  end

  def test_build_dict_multiple_sources_more_than_two
    data = [
      { "key" => "Key:example", "url" => "http://example1.com/$1", "rank" => "normal", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "normal", "source" => "wikidata:P1630" },
      { "key" => "Key:example", "url" => "http://example3.com/$1", "rank" => "normal", "source" => "other:source" }
    ]
    dict = Tag2link.build_dict(data)
    # Should not happen with current tag2link schema, but ensure we handle it gracefully
    assert_not_includes dict, "example"
  end
end
