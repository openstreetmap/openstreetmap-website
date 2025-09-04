# frozen_string_literal: true

# == Schema Information
#
# Table name: social_links
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           not null
#  url        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_social_links_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class SocialLink < ApplicationRecord
  belongs_to :user

  validates :url, :format => { :with => %r{\A(https?://.+|@([a-zA-Z0-9_]+)@([\w\-.]+))\z}, :message => :http_parse_error }

  URL_PATTERNS = {
    :bluesky => %r{\Ahttps?://(?:www\.)?bsky\.app/profile/([a-zA-Z0-9._-]+)},
    :discord => %r{\Ahttps?://(?:www\.)?discord\.com/users/(\d+)},
    :facebook => %r{\Ahttps?://(?:www\.)?facebook\.com/([a-zA-Z0-9.]+)},
    :flickr => %r{\Ahttps?://(?:www\.)?flickr\.com/people/([a-zA-Z0-9@._-]+)},
    :github => %r{\Ahttps?://(?:www\.)?github\.com/([a-zA-Z0-9_-]+)},
    :gitlab => %r{\Ahttps?://(?:www\.)?gitlab\.com/([a-zA-Z0-9_-]+)},
    :hdyc => %r{\Ahttps?://(?:www\.)?hdyc\.neis-one\.org/\?([a-zA-Z0-9_-]+)},
    :hot => %r{\Ahttps?://tasks\.hotosm\.org/users/([a-zA-Z0-9_-]+)},
    :instagram => %r{\Ahttps?://(?:www\.)?instagram\.com/([a-zA-Z0-9._]+)},
    :linkedin => %r{\Ahttps?://(?:www\.)?linkedin\.com/in/([a-zA-Z0-9_-]+)},
    :line => %r{\Ahttps?://(?:www\.)?line\.me/ti/p/([a-zA-Z0-9_-]+)},
    :mapillary => %r{\Ahttps?://(?:www\.)?mapillary\.com/(?:app/user|profile)/([a-zA-Z0-9_-]+)},
    :mastodon => %r{\Ahttps?://(?:(?:www\.)?(mastodon\.social|en\.osm\.town))/(@[a-zA-Z0-9_]+)},
    :mastodon_general => /\A@([a-zA-Z0-9_]+)@([\w\-.]+)/,
    :medium => %r{\Ahttps?://(?:www\.)?medium\.com/@([a-zA-Z0-9_]+)},
    :ogf => %r{\Ahttps?://wiki\.opengeofiction\.net/index\.php/User:([a-zA-Z0-9_-]+)},
    :ohm => %r{\Ahttps?://(?:www\.)?openhistoricalmap\.org/user/(\S+)},
    :osm_forum => %r{\Ahttps?://community\.openstreetmap\.org/u/(\S+)},
    :osm_wiki => %r{\Ahttps?://wiki\.openstreetmap\.org/wiki/User:([a-zA-Z0-9_-]+)},
    :quora => %r{\Ahttps?://(?:www\.)?quora\.com/profile/([a-zA-Z0-9_-]+)},
    :reddit => %r{\Ahttps?://(?:www\.)?reddit\.com/user/([a-zA-Z0-9_-]+)},
    :slack => %r{\Ahttps?://join\.slack\.com/shareDM/([a-zA-Z0-9_~-]+)},
    :snapchat => %r{\Ahttps?://(?:www\.)?snapchat\.com/add/([a-zA-Z0-9_-]+)},
    :stackoverflow => %r{\Ahttps?://(?:www\.)?stackoverflow\.com/users/\d+/([a-zA-Z0-9_-]+)},
    :strava => %r{\Ahttps?://(?:www\.)?strava\.com/athletes/([a-zA-Z0-9_-]+)},
    :substack => %r{\Ahttps?://(?:www\.)?substack\.com/@([a-zA-Z0-9_-]+)},
    :telegram => %r{\Ahttps?://(?:www\.)?t\.me/([a-zA-Z0-9_]+)},
    :threads => %r{\Ahttps?://(?:www\.)?threads\.net/@([a-zA-Z0-9_]+)},
    :tiktok => %r{\Ahttps?://(?:www\.)?tiktok\.com/@([a-zA-Z0-9_]+)},
    :twitch => %r{\Ahttps?://(?:www\.)?twitch\.tv/([a-zA-Z0-9_]+)},
    :twitter_x => %r{\Ahttps?://(?:www\.)?(?:twitter|x)\.com/([a-zA-Z0-9_]+)},
    :vimeo => %r{\Ahttps?://(?:www\.)?vimeo\.com/([a-zA-Z0-9_]+)},
    :whatsapp => %r{\Ahttps?://wa\.me/(\d+)},
    :wikidata => %r{\Ahttps?://(?:www\.)?wikidata\.org/wiki/User:([a-zA-Z0-9_-]+)},
    :wikimedia => %r{\Ahttps?://commons\.wikimedia\.org/wiki/User:([a-zA-Z0-9_-]+)},
    :wikipedia => %r{\Ahttps?://(?:[a-zA-Z]+\.)?wikipedia\.org/wiki/User:([a-zA-Z0-9_-]+)},
    :wikivoyage => %r{\Ahttps?://(?:[a-zA-Z]+\.)?wikivoyage\.org/wiki/User:([a-zA-Z0-9_-]+)},
    :youtube => %r{\Ahttps?://(?:www\.)?youtube\.com/@([a-zA-Z0-9_-]+)}
  }.freeze

  NO_USERNAME_PLATFORMS = %w[discord line slack].freeze

  def parsed
    URL_PATTERNS.each do |platform, pattern|
      names = url.match(pattern)
      next unless names

      if platform == :mastodon_general
        return {
          :url => "https://#{names[2]}/@#{names[1]}",
          :platform => "mastodon",
          :name => "@#{names[1]}@#{names[2]}"
        }
      end

      name = names[2].nil? ? names[1] : "#{names[2]}@#{names[1]}"
      name = platform.to_s.capitalize if NO_USERNAME_PLATFORMS.include?(platform.to_s)

      return {
        :url => url,
        :platform => platform.to_s,
        :name => name
      }
    end
    { :url => url, :platform => nil, :name => url.gsub(%r{https?://}, "") }
  end
end
