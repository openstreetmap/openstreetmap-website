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

  validates :url, :presence => true, :format => { :with => URI::DEFAULT_PARSER.make_regexp(%w[http https]), :message => I18n.t("profiles.edit.social_links.http_parse_error") }

  URL_PATTERNS = {
    :discord => %r{discord\.com/users/(\d+)},
    :facebook => %r{facebook\.com/([a-zA-Z0-9.]+)},
    :github => %r{github\.com/([a-zA-Z0-9_-]+)},
    :gitlab => %r{gitlab\.com/([a-zA-Z0-9_-]+)},
    :instagram => %r{instagram\.com/([a-zA-Z0-9._]+)},
    :linkedin => %r{linkedin\.com/in/([a-zA-Z0-9_-]+)},
    :line => %r{line\.me/ti/p/([a-zA-Z0-9_-]+)},
    :mastodon => %r{mastodon\.social/@([a-zA-Z0-9_]+)},
    :medium => %r{medium\.com/@([a-zA-Z0-9_]+)},
    :quora => %r{quora\.com/profile/([a-zA-Z0-9_-]+)},
    :reddit => %r{reddit\.com/user/([a-zA-Z0-9_-]+)},
    :skype => %r{join\.skype\.com/invite/([a-zA-Z0-9_-]+)},
    :slack => %r{join\.slack\.com/shareDM/([a-zA-Z0-9_~-]+)},
    :snapchat => %r{snapchat\.com/add/([a-zA-Z0-9_-]+)},
    :stackoverflow => %r{stackoverflow\.com/users/(\d+/[a-zA-Z0-9_-]+)},
    :strava => %r{strava\.com/athletes/([a-zA-Z0-9_-]+)},
    :substack => %r{substack\.com/@([a-zA-Z0-9_-]+)},
    :telegram => %r{t\.me/([a-zA-Z0-9_]+)},
    :threads => %r{threads\.net/@([a-zA-Z0-9_]+)},
    :tiktok => %r{tiktok\.com/@([a-zA-Z0-9_]+)},
    :twitch => %r{twitch\.tv/([a-zA-Z0-9_]+)},
    :twitter_x => %r{(?:twitter|x)\.com/([a-zA-Z0-9_]+)},
    :vimeo => %r{vimeo.com/([a-zA-Z0-9_]+)},
    :whatsapp => %r{wa\.me/(\d+)},
    :youtube => %r{youtube\.com/@([a-zA-Z0-9_-]+)}
  }.freeze

  NO_USERNAME_PLATFORMS = %w[discord line skype slack].freeze

  def parsed
    URL_PATTERNS.each do |platform, pattern|
      username = url.match(pattern)
      if username
        return {
          :platform => platform.to_s,
          :name => NO_USERNAME_PLATFORMS.include?(platform.to_s) ? platform.to_s.capitalize : username[1]
        }
      end
    end
    { :platform => nil, :name => url }
  end
end
