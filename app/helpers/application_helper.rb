module ApplicationHelper
  require "rexml/document"

  def linkify(text)
    if text.html_safe?
      Rinku.auto_link(text, :urls, tag_builder.tag_options(:rel => "nofollow")).html_safe
    else
      Rinku.auto_link(ERB::Util.h(text), :urls, tag_builder.tag_options(:rel => "nofollow")).html_safe
    end
  end

  def rss_link_to(*args)
    link_to(image_tag("RSS.png", :size => "16x16", :border => 0), Hash[*args], :class => "rsssmall")
  end

  def atom_link_to(*args)
    link_to(image_tag("RSS.png", :size => "16x16", :border => 0), Hash[*args], :class => "rsssmall")
  end

  def richtext_area(object_name, method, options = {})
    id = "#{object_name}_#{method}"
    type = options.delete(:format) || "markdown"

    content_tag(:div, :id => "#{id}_container", :class => "richtext_container") do
      output_buffer << content_tag(:div, :id => "#{id}_content", :class => "richtext_content") do
        output_buffer << text_area(object_name, method, options.merge("data-preview-url" => preview_url(:type => type)))
        output_buffer << content_tag(:div, "", :id => "#{id}_preview", :class => "richtext_preview richtext")
      end

      output_buffer << content_tag(:div, :id => "#{id}_help", :class => "richtext_help") do
        output_buffer << render("site/#{type}_help")
        output_buffer << content_tag(:div, :class => "buttons") do
          output_buffer << submit_tag(I18n.t("site.richtext_area.edit"), :id => "#{id}_doedit", :class => "richtext_doedit deemphasize", :disabled => true)
          output_buffer << submit_tag(I18n.t("site.richtext_area.preview"), :id => "#{id}_dopreview", :class => "richtext_dopreview deemphasize")
        end
      end
    end
  end

  def dir
    if dir = params[:dir]
      dir == "rtl" ? "rtl" : "ltr"
    else
      I18n.t("html.dir")
    end
  end

  def friendly_date(date)
    content_tag(:span, time_ago_in_words(date), :title => l(date, :format => :friendly))
  end

  def friendly_date_ago(date)
    content_tag(:span, time_ago_in_words(date, :scope => :'datetime.distance_in_words_ago'), :title => l(date, :format => :friendly))
  end

  def body_class
    if content_for? :body_class
      content_for :body_class
    else
      "#{params[:controller]} #{params[:controller]}-#{params[:action]}"
    end
  end

  def current_page_class(path)
    :current if current_page?(path)
  end

  def application_data
    data = {
      :locale => I18n.locale,
      :preferred_editor => preferred_editor
    }

    if current_user
      data[:user] = current_user.id.to_json

      data[:user_home] = { :lat => current_user.home_lat, :lon => current_user.home_lon } unless current_user.home_lon.nil? || current_user.home_lat.nil?
    end

    data[:location] = session[:location] if session[:location]

    if @oauth
      data[:token] = @oauth.token
      data[:token_secret] = @oauth.secret
      data[:consumer_key] = @oauth.client_application.key
      data[:consumer_secret] = @oauth.client_application.secret
    end

    data
  end
end
