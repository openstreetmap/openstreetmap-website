# frozen_string_literal: true

module ShareButtonsHelper
  SHARE_BUTTONS_CONFIG = [
    { :site => "share", :type => "native", :button => "secondary", :icon => "share-fill", :href => "#text={title}&url={url}" },
    { :site => "email", :type => "email", :icon => "envelope-fill", :href => "mailto:?subject={title}&body={url}" },
    { :site => "bluesky", :href => "https://bsky.app/intent/compose?text={title}+{url}" },
    { :site => "facebook", :href => "https://www.facebook.com/sharer/sharer.php?t={title}&u={url}" },
    { :site => "linkedin", :href => "https://www.linkedin.com/sharing/share-offsite/?url={url}" },
    { :site => "mastodon", :href => "https://mastodonshare.com/?text={title}&url={url}" },
    { :site => "telegram", :href => "https://t.me/share/url?text={title}&url={url}" },
    { :site => "x", :icon => "twitter-x", :href => "https://x.com/intent/tweet?text={title}&url={url}" }
  ].freeze

  # Generates a set of share buttons based on the specified options.
  def share_buttons(title:, url:)
    tag.div(
      :class => "d-flex gap-1 align-items-end flex-wrap mb-3"
    ) do
      safe_join(SHARE_BUTTONS_CONFIG.map do |share|
        link_options = {
          :rel => "nofollow",
          :class => "btn btn-#{share[:button] || share[:site]} px-1 py-0 border-2 rounded-circle focus-ring",
          :title => I18n.t("application.share.#{share[:site]}.title"),
          :target => "_blank",
          :hidden => share[:type] == "native",
          :data => { :share_type => share[:type] || "site" }
        }
        share_url = share[:href]
                    .gsub("{title}", URI.encode_uri_component(title))
                    .gsub("{url}", URI.encode_uri_component(url))

        link_to share_url, link_options do
          tag.i(:class => "bi bi-#{share[:icon] || share[:site]}", :aria => { :label => I18n.t("application.share.#{share[:site]}.alt") })
        end
      end, "\n")
    end
  end
end
