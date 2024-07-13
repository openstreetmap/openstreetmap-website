module ApplicationHelper
  require "rexml/document"
  include SocialShareButtonHelper

  def linkify(text)
    if text.html_safe?
      Rinku.auto_link(text, :urls, tag_builder.tag_options(:rel => "nofollow")).html_safe
    else
      Rinku.auto_link(ERB::Util.h(text), :urls, tag_builder.tag_options(:rel => "nofollow")).html_safe
    end
  end

  def rss_link_to(args = {})
    link_to image_tag("RSS.png", :size => "16x16", :class => "align-text-bottom"), args
  end

  def atom_link_to(args = {})
    link_to image_tag("RSS.png", :size => "16x16", :class => "align-text-bottom"), args
  end

  def dir
    if dir = params[:dir]
      dir == "rtl" ? "rtl" : "ltr"
    else
      I18n.t("html.dir")
    end
  end

  def friendly_date(date)
    tag.time(time_ago_in_words(date), :title => l(date, :format => :friendly), :datetime => date.xmlschema)
  end

  def friendly_date_ago(date)
    tag.time(time_ago_in_words(date, :scope => :"datetime.distance_in_words_ago"), :title => l(date, :format => :friendly), :datetime => date.xmlschema)
  end

  def body_class
    if content_for? :body_class
      content_for :body_class
    else
      "#{params[:controller]} #{params[:controller]}-#{params[:action]}"
    end
  end

  def header_nav_link_class(path)
    ["nav-link", current_page?(path) ? "text-secondary-emphasis" : "text-secondary"]
  end

  def application_data
    data = {
      :locale => I18n.locale,
      :preferred_editor => preferred_editor,
      :preferred_languages => preferred_languages.expand.map(&:to_s)
    }

    if current_user
      data[:user] = current_user.id.to_json

      data[:user_home] = { :lat => current_user.home_lat, :lon => current_user.home_lon } if current_user.home_location?
    end

    data[:location] = session[:location] if session[:location]
    data[:oauth_token] = oauth_token.token if oauth_token

    data
  end

  # If the flash is a hash, then it will be a partial with a hash of locals, so we can call `render` on that
  # This allows us to render html into a flash message in a safe manner.
  def render_flash(flash)
    if flash.is_a?(Hash)
      render flash.with_indifferent_access
    else
      flash
    end
  rescue StandardError
    flash.inspect if Rails.env.development?
  end

  # Generates a set of social share buttons based on the specified options.
  def render_social_share_buttons(opts = {})
    sites = opts.fetch(:allow_sites, [])

    valid_sites, invalid_sites = SocialShareButtonHelper.filter_allowed_sites(sites)

    # Log invalid providers
    invalid_sites.each do |invalid_site|
      Rails.logger.error("Invalid site or icon not configured: #{invalid_site}")
    end

    content_tag(
      :div,
      :class => "social-share-button d-flex gap-1 align-items-end flex-wrap",
      :data => {
        :title => opts[:title],
        :url => opts[:url],
        :desc => opts[:desc],
        :via => opts[:via]
      }
    ) do
      social_buttons = valid_sites.filter_map do |site|
        if SocialShareButtonHelper.icon_path(site).empty?
          Rails.logger.error("Invalid site: #{site}")
          next
        end

        link_to "", {
          :rel => ["nofollow", opts[:rel]].compact,
          :data => { :site => site, :title => opts[:title], :desc => opts[:desc], :url => opts[:url] },
          :class => "social-share-button ssb-icon",
          :onclick => "return SocialShareButton.share(this);"
        } do
          image_tag(SocialShareButtonHelper.icon_path(site), :alt => site.capitalize, :size => 28)
        end
      end.join.html_safe

      social_buttons
    end
  end
end
