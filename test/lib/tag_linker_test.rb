# frozen_string_literal: true

require "test_helper"

class TagLinkerTest < ActiveSupport::TestCase
  def test_wiki_link
    link = TagLinker.wiki_link("key", "highway")
    assert_equal "https://wiki.openstreetmap.org/wiki/Key:highway?uselang=en", link

    link = TagLinker.wiki_link("tag", "highway=primary")
    assert_equal "https://wiki.openstreetmap.org/wiki/Tag:highway=primary?uselang=en", link

    I18n.with_locale "de" do
      link = TagLinker.wiki_link("key", "highway")
      assert_equal "https://wiki.openstreetmap.org/wiki/DE:Key:highway?uselang=de", link

      link = TagLinker.wiki_link("tag", "highway=primary")
      assert_equal "https://wiki.openstreetmap.org/wiki/DE:Tag:highway=primary?uselang=de", link
    end

    I18n.with_locale "tr" do
      link = TagLinker.wiki_link("key", "highway")
      assert_equal "https://wiki.openstreetmap.org/wiki/Tr:Key:highway?uselang=tr", link

      link = TagLinker.wiki_link("tag", "highway=path")
      assert_equal "https://wiki.openstreetmap.org/wiki/Tag:highway=path?uselang=tr", link
    end
  end

  def test_tag2link_link
    assert_nil TagLinker.tag2link_link("website", "https://example.com/page")

    assert_nil TagLinker.tag2link_link("nonexistent_key", "SomeValue")

    url = TagLinker.tag2link_link("wikidata", "Q936")
    assert_equal "https://www.wikidata.org/entity/Q936", url

    url = TagLinker.tag2link_link("hashtags", "#maproulette")
    assert_equal "https://resultmaps.neis-one.org/osm-changesets?comment=maproulette", url
  end

  def test_build_tag2link_dict_rejects_deprecated_and_third_party
    data = [
      { "key" => "Key:example", "url" => "http://example.com/$1", "rank" => "deprecated", "source" => "osmwiki:P8" },
      { "key" => "Key:example2", "url" => "http://example2.com/$1", "rank" => "preferred", "source" => "wikidata:P3303" },
      { "key" => "Key:example3", "url" => "http://example3.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" }
    ]
    dict = TagLinker.build_tag2link_dict(data)
    assert_not_includes dict, "example"
    assert_not_includes dict, "example2"
    assert_includes dict, "example3"
  end

  def test_build_tag2link_dict_chooses_single_preferred_item
    data = [
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "normal", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" }
    ]
    dict = TagLinker.build_tag2link_dict(data)
    assert_equal "http://example.com/$1", dict["example"]

    data = [
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example.com/$1", "rank" => "preferred", "source" => "wikidata:P1630" },
      { "key" => "Key:example", "url" => "http://example3.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" }
    ]
    dict = TagLinker.build_tag2link_dict(data)
    assert_equal "http://example.com/$1", dict["example"]

    data = [
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" }
    ]
    dict = TagLinker.build_tag2link_dict(data)
    assert_equal "http://example2.com/$1", dict["example"]
  end

  def test_build_tag2link_dict_deduplicates_urls
    data = [
      { "key" => "Key:example", "url" => "http://example.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example.com/$1", "rank" => "normal", "source" => "wikidata:P1630" }
    ]
    dict = TagLinker.build_tag2link_dict(data)
    assert_equal "http://example.com/$1", dict["example"]
  end

  def test_build_tag2link_dict_rejects_multiple_equally_preferred_items
    data = [
      { "key" => "Key:example", "url" => "http://example1.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" }
    ]
    dict = TagLinker.build_tag2link_dict(data)
    assert_not_includes dict, "example"

    data = [
      { "key" => "Key:example", "url" => "http://example1.com/$1", "rank" => "normal", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "normal", "source" => "osmwiki:P8" }
    ]
    dict = TagLinker.build_tag2link_dict(data)
    assert_not_includes dict, "example"
  end

  def test_build_tag2link_dict_chooses_osmwiki_when_both_have_single_preferred
    data = [
      { "key" => "Key:example", "url" => "http://example1.com/$1", "rank" => "preferred", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "preferred", "source" => "wikidata:P1630" }
    ]
    dict = TagLinker.build_tag2link_dict(data)
    assert_equal "http://example1.com/$1", dict["example"]

    data = [
      { "key" => "Key:example", "url" => "http://example1.com/$1", "rank" => "normal", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "normal", "source" => "wikidata:P1630" }
    ]
    dict = TagLinker.build_tag2link_dict(data)
    assert_equal "http://example1.com/$1", dict["example"]
  end

  def test_build_tag2link_dict_multiple_sources_more_than_two
    data = [
      { "key" => "Key:example", "url" => "http://example1.com/$1", "rank" => "normal", "source" => "osmwiki:P8" },
      { "key" => "Key:example", "url" => "http://example2.com/$1", "rank" => "normal", "source" => "wikidata:P1630" },
      { "key" => "Key:example", "url" => "http://example3.com/$1", "rank" => "normal", "source" => "other:source" }
    ]
    dict = TagLinker.build_tag2link_dict(data)
    # Should not happen with current tag2link schema, but ensure we handle it gracefully
    assert_not_includes dict, "example"
  end
end
