module ApplicationHelper
  require "rexml/document"

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

  def plus_icon
    '<svg width="16" height="16">
      <path d="M2 0 a2 2 0 0 0 -2 2 v12 a2 2 0 0 0 2 2 h12 a2 2 0 0 0 2 -2 v-12 a2 2 0 0 0 -2 -2 z M4 7 h3 v-3 h2 v3 h3 v2 h-3 v3 h-2 v-3 h-3 z" fill="currentColor" />
    </svg>'.html_safe
  end
end
