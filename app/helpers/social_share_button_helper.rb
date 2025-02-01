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
  def social_share_buttons(title:, url:)
    tag.div(
      :class => "social-share-button d-flex gap-1 align-items-end flex-wrap mb-3"
    ) do
      safe_join(SOCIAL_SHARE_CONFIG.map do |site, icon|
        link_options = {
          :rel => "nofollow",
          :class => "ssb-icon rounded-circle",
          :title => I18n.t("application.share.#{site}.title"),
          :target => "_blank"
        }

        link_to generate_share_url(site, title, url), link_options do
          image_tag(icon, :alt => I18n.t("application.share.#{site}.alt"), :size => 28)
        end
      end, "\n")
    end
  end

  private

  def generate_share_url(site, title, url)
    site = site.to_sym
    title = URI.encode_uri_component(title)
    url = URI.encode_uri_component(url)

    case site
    when :email
      "mailto:?subject=#{title}&body=#{url}"
    when :x
      "https://x.com/intent/tweet?url=#{url}&text=#{title}"
    when :linkedin
      "https://www.linkedin.com/sharing/share-offsite/?url=#{url}"
    when :facebook
      "https://www.facebook.com/sharer/sharer.php?u=#{url}&t=#{title}"
    when :mastodon
      "https://mastodonshare.com/?text=#{title}&url=#{url}"
    when :telegram
      "https://t.me/share/url?url=#{url}&text=#{title}"
    when :bluesky
      "https://bsky.app/intent/compose?text=#{title}+#{url}"
    else
      raise ArgumentError, "Unsupported platform: #{platform}"
    end
  end
end
