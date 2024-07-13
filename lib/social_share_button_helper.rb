module SocialShareButtonHelper
  SOCIAL_SHARE_CONFIG = {
    "email" => "social_icons/email.svg",
    "facebook" => "social_icons/facebook.svg",
    "linkedin" => "social_icons/linkedin.svg",
    "mastodon" => "social_icons/mastodon.svg",
    "telegram" => "social_icons/telegram.svg",
    "twitter" => "social_icons/twitter.svg"
  }.freeze

  def self.filter_allowed_sites(sites)
    if sites.empty?
      valid_sites = SOCIAL_SHARE_CONFIG.keys
      invalid_sites = []
    else
      valid_sites = sites.select { |site| valid_site?(site) }
      invalid_sites = sites.reject { |site| valid_site?(site) }
    end

    [valid_sites, invalid_sites]
  end

  def self.icon_path(site)
    SOCIAL_SHARE_CONFIG[site] || ""
  end

  def self.valid_site?(site)
    SOCIAL_SHARE_CONFIG.key?(site)
  end
end
