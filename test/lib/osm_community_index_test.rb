require "test_helper"

class CountryTest < ActiveSupport::TestCase
  def test_community_name_fallback
    # If there is no translations and no name for the chapter, use the community name
    community = Community.new({ "id" => "foo-chapter", "type" => "osm-lc", "strings" => { "community" => "Community Name" } })
    community_locale_yaml = {}
    community_en_yaml = {}

    name = OsmCommunityIndex.resolve_name(community, community_locale_yaml, community_en_yaml)
    assert_equal("Community Name", name)
  end

  def test_resource_name_fallback
    # If there is a name for the chapter, prefer that to the community name
    community = Community.new({ "id" => "foo-chapter", "type" => "osm-lc", "strings" => { "community" => "Community Name", "name" => "Chapter Name" } })
    community_locale_yaml = {}
    community_en_yaml = {}

    name = OsmCommunityIndex.resolve_name(community, community_locale_yaml, community_en_yaml)
    assert_equal("Chapter Name", name)
  end

  def test_i18n_explicit_name
    # If there is an explicitly translated name for the chapter, use that
    community = Community.new({ "id" => "foo-chapter", "type" => "osm-lc", "strings" => { "community" => "Community Name", "name" => "Chapter Name" } })
    community_locale_yaml = { "foo-chapter" => { "name" => "Translated Chapter Name" } }
    community_en_yaml = {}

    name = OsmCommunityIndex.resolve_name(community, community_locale_yaml, community_en_yaml)
    assert_equal("Translated Chapter Name", name)
  end

  def test_i18n_fallback_name
    # If there's no explicitly translated name for the chapter, use the default name and interpolate the community name if required.
    community = Community.new({ "id" => "foo-chapter", "type" => "osm-lc", "strings" => { "community" => "Community Name", "communityID" => "communityname" } })
    community_locale_yaml = { "_communities" => { "communityname" => "Translated Community" }, "_defaults" => { "osm-lc" => { "name" => "{community} Chapter" } } }
    community_en_yaml = {}

    name = OsmCommunityIndex.resolve_name(community, community_locale_yaml, community_en_yaml)
    assert_equal("Translated Community Chapter", name)
  end

  def test_i18n_invalid_replacement_token
    # Ignore invalid replacement tokens in OCI data provided. This might happen if translators were mistakenly translating the predefined token ids.
    community = Community.new({ "id" => "foo-chapter", "type" => "osm-lc", "strings" => { "community" => "Community Name", "communityID" => "communityname" } })
    community_locale_yaml = { "_communities" => { "communityname" => "Translated Community" }, "_defaults" => { "osm-lc" => { "name" => "{comminauté} Chapter" } } }
    community_en_yaml = {}

    name = OsmCommunityIndex.resolve_name(community, community_locale_yaml, community_en_yaml)
    assert_equal("Community Name", name)
  end
end
