module ShareButtonsHelper
  require "uri"

  SHARE_BUTTONS_CONFIG = {
    :email => "share_button_icons/email.svg",
    :bluesky => "share_button_icons/bluesky.svg",
    :facebook => "share_button_icons/facebook.svg",
    :linkedin => "share_button_icons/linkedin.svg",
    :mastodon => "share_button_icons/mastodon.svg",
    :telegram => "share_button_icons/telegram.svg",
    :x => "share_button_icons/x.svg"
  }.freeze

  # Generates a set of share buttons based on the specified options.
  def share_buttons(title:, url:)
    tag.div(
      :class => "d-flex gap-1 align-items-end flex-wrap mb-3"
    ) do
      buttons = [
        tag.button(:type => "button",
                   :class => "btn btn-secondary p-1 border-1 rounded-circle",
                   :title => I18n.t("application.share.share.title"),
                   :hidden => true,
                   :data => { :share_type => "native",
                              :share_text => title,
                              :share_url => url }) do
          image_tag("share_button_icons/share.svg", :alt => I18n.t("application.share.share.alt"), :size => 18, :class => "d-block")
        end
      ]

      buttons << SHARE_BUTTONS_CONFIG.map do |site, icon|
        link_options = {
          :rel => "nofollow",
          :class => "rounded-circle focus-ring",
          :title => I18n.t("application.share.#{site}.title"),
          :target => "_blank",
          :data => { :share_type => site == :email ? "email" : "site" }
        }

        link_to generate_share_url(site, title, url), link_options do
          image_tag(icon, :alt => I18n.t("application.share.#{site}.alt"), :size => 28)
        end
      end

      safe_join(buttons, "\n")
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
