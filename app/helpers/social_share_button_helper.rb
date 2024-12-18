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

  # Generates a set of social share buttons based on the specified options.
  def social_share_buttons(opts = {})
    tag.div(
      :class => "social-share-button d-flex gap-1 align-items-end flex-wrap mb-3"
    ) do
      SOCIAL_SHARE_CONFIG.map do |site, icon|
        link_options = {
          :rel => ["nofollow", opts[:rel]].compact,
          :class => "ssb-icon rounded-circle",
          :title => I18n.t("application.share.#{site}.title"),
          :target => "_blank"
        }

        link_to generate_share_url(site, opts), link_options do
          image_tag(icon, :alt => I18n.t("application.share.#{site}.alt"), :size => 28)
        end
      end.join.html_safe
    end
  end

  private

  def generate_share_url(site, params)
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
