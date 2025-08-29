# frozen_string_literal: true

require "test_helper"

class SocialLinkTest < ActiveSupport::TestCase
  def test_user_required
    social_link = create(:social_link)

    assert_predicate social_link, :valid?
    social_link.user = nil
    assert_not_predicate social_link, :valid?
  end

  def test_url_required
    social_link = create(:social_link)

    assert_predicate social_link, :valid?
    social_link.url = nil
    assert_not_predicate social_link, :valid?
  end

  def test_url_https_valid
    social_link = create(:social_link)

    assert_predicate social_link, :valid?
    social_link.url = "test"
    assert_not_predicate social_link, :valid?
  end

  def test_parsed_platform
    social_link = create(:social_link, :url => "https://github.com/test")

    assert_equal "github", social_link.parsed[:platform]
    assert_equal "test", social_link.parsed[:name]
  end

  def test_parsed_platform_with_www
    social_link = create(:social_link, :url => "http://www.github.com/test")

    assert_equal "github", social_link.parsed[:platform]
    assert_equal "test", social_link.parsed[:name]
  end

  def test_parsed_platform_custom_name
    social_link = create(:social_link, :url => "https://discord.com/users/0")

    assert_equal "discord", social_link.parsed[:platform]
    assert_equal "Discord", social_link.parsed[:name]
  end

  def test_parsed_platform_mastodon
    social_link = create(:social_link, :url => "https://mastodon.social/@test")

    assert_equal "mastodon", social_link.parsed[:platform]
    assert_equal "@test@mastodon.social", social_link.parsed[:name]
  end

  def test_parsed_platform_mastodon_parsed
    social_link = create(:social_link, :url => "@test@mapstodon.space")

    assert_equal "https://mapstodon.space/@test", social_link.parsed[:url]
    assert_equal "mastodon", social_link.parsed[:platform]
    assert_equal "@test@mapstodon.space", social_link.parsed[:name]
  end

  def test_parsed_platform_other
    url = "https://test.com/test"
    expected = "test.com/test"
    social_link = create(:social_link, :url => url)

    assert_nil social_link.parsed[:platform]
    assert_equal social_link.parsed[:name], expected
  end
end
