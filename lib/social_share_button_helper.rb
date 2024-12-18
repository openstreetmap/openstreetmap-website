module SocialShareButtonHelper
  require "uri"

  SOCIAL_SHARE_CONFIG = {
    :email => "social_icons/email.svg",
    :bluesky => "social_icons/bluesky.svg",
    :facebook => "social_icons/facebook.svg",
    :linkedin => "social_icons/linkedin.svg",
    :mastodon => "social_icons/mastodon.svg",
    :telegram => "social_icons/telegram.svg",
    :x => "social_icons/x.svg"
  }.freeze

  def self.filter_allowed_sites(sites)
    valid_sites = sites.empty? ? SOCIAL_SHARE_CONFIG.keys : sites.select { |site| valid_site?(site) }
    invalid_sites = sites - valid_sites
    [valid_sites, invalid_sites]
  end

  def self.icon_path(site)
    SOCIAL_SHARE_CONFIG[site.to_sym] || ""
  end

  def self.valid_site?(site)
    SOCIAL_SHARE_CONFIG.key?(site.to_sym)
  end

  def self.generate_share_url(site, params)
    site = site.to_sym
    case site
    when :email
      to = params[:to] || ""
      subject = CGI.escape(params[:title])
      body = CGI.escape(params[:url])
      "mailto:#{to}?subject=#{subject}&body=#{body}"
    when :x
      via_str = params[:via] ? "&via=#{URI.encode_www_form_component(params[:via])}" : ""
      hashtags_str = params[:hashtags] ? "&hashtags=#{URI.encode_www_form_component(params[:hashtags].join(','))}" : ""
      "https://x.com/intent/tweet?url=#{URI.encode_www_form_component(params[:url])}&text=#{URI.encode_www_form_component(params[:title])}#{hashtags_str}#{via_str}"
    when :linkedin
      "https://www.linkedin.com/sharing/share-offsite/?url=#{URI.encode_www_form_component(params[:url])}"
    when :facebook
      "https://www.facebook.com/sharer/sharer.php?u=#{URI.encode_www_form_component(params[:url])}&t=#{URI.encode_www_form_component(params[:title])}"
    when :mastodon
      "https://mastodonshare.com/?text=#{URI.encode_www_form_component(params[:title])}&url=#{URI.encode_www_form_component(params[:url])}"
    when :telegram
      "https://t.me/share/url?url=#{URI.encode_www_form_component(params[:url])}&text=#{URI.encode_www_form_component(params[:title])}"
    when :bluesky
      "https://bsky.app/intent/compose?text=#{URI.encode_www_form_component(params[:title])}+#{URI.encode_www_form_component(params[:url])}"
    else
      raise ArgumentError, "Unsupported platform: #{platform}"
    end
  end
end
