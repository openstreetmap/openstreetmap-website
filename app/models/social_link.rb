# == Schema Information
#
# Table name: social_links
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)        not null
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

  validates :url, :format => { :with => %r{\Ahttps?://.+\z}, :message => :http_parse_error }

  URL_PATTERNS = {
    :bluesky => %r{\Ahttps?://(?:www\.)?bsky\.app/profile/([a-zA-Z0-9\._-]+)},
    :discord => %r{\Ahttps?://(?:www\.)?discord\.com/users/(\d+)},
    :facebook => %r{\Ahttps?://(?:www\.)?facebook\.com/([a-zA-Z0-9.]+)},
    :github => %r{\Ahttps?://(?:www\.)?github\.com/([a-zA-Z0-9_-]+)},
    :gitlab => %r{\Ahttps?://(?:www\.)?gitlab\.com/([a-zA-Z0-9_-]+)},
    :instagram => %r{\Ahttps?://(?:www\.)?instagram\.com/([a-zA-Z0-9._]+)},
    :linkedin => %r{\Ahttps?://(?:www\.)?linkedin\.com/in/([a-zA-Z0-9_-]+)},
    :line => %r{\Ahttps?://(?:www\.)?line\.me/ti/p/([a-zA-Z0-9_-]+)},
    :mastodon => %r{\Ahttps?://(?:(?:www\.)?mastodon\.social|en\.osm\.town)/@([a-zA-Z0-9_]+)},
    :medium => %r{\Ahttps?://(?:www\.)?medium\.com/@([a-zA-Z0-9_]+)},
    :quora => %r{\Ahttps?://(?:www\.)?quora\.com/profile/([a-zA-Z0-9_-]+)},
    :reddit => %r{\Ahttps?://(?:www\.)?reddit\.com/user/([a-zA-Z0-9_-]+)},
    :skype => %r{\Ahttps?://join\.skype\.com/invite/([a-zA-Z0-9_-]+)},
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
    :youtube => %r{\Ahttps?://(?:www\.)?youtube\.com/@([a-zA-Z0-9_-]+)}
  }.freeze

  NO_USERNAME_PLATFORMS = %w[discord line skype slack].freeze

  def parsed
    URL_PATTERNS.each do |platform, pattern|
      names = url.match(pattern)
      if names
        return {
          :platform => platform.to_s,
          :name => NO_USERNAME_PLATFORMS.include?(platform.to_s) ? platform.to_s.capitalize : names[1]
        }
      end
    end
    { :platform => nil, :name => url.gsub(%r{https?://}, "") }
  end
end
