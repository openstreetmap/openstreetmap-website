module ApplicationHelper
  require "rexml/document"

  def linkify(text)
    if text.html_safe?
      Rinku.auto_link(text, :urls, tag_options(:rel => "nofollow")).html_safe
    else
      Rinku.auto_link(text, :urls, tag_options(:rel => "nofollow"))
    end
  end

  def rss_link_to(*args)
    link_to(image_tag("RSS.png", :size => "16x16", :border => 0), Hash[*args], :class => "rsssmall")
  end

  def atom_link_to(*args)
    link_to(image_tag("RSS.png", :size => "16x16", :border => 0), Hash[*args], :class => "rsssmall")
  end

  def style_rules
    css = ""

    css << ".hidden { display: none !important }"
    css << ".hide_unless_logged_in { display: none !important }" unless @user
    css << ".hide_if_logged_in { display: none !important }" if @user
    css << ".hide_if_user_#{@user.id} { display: none !important }" if @user
    css << ".show_if_user_#{@user.id} { display: inline !important }" if @user
    css << ".hide_unless_administrator { display: none !important }" unless @user && @user.administrator?
    css << ".hide_unless_moderator { display: none !important }" unless @user && @user.moderator?

    content_tag(:style, css, :type => "text/css")
  end

  def if_logged_in(tag = :div, &block)
    content_tag(tag, capture(&block), :class => "hide_unless_logged_in")
  end

  def if_not_logged_in(tag = :div, &block)
    content_tag(tag, capture(&block), :class => "hide_if_logged_in")
  end

  def if_user(user, tag = :div, &block)
    if user
      content_tag(tag, capture(&block), :class => "hidden show_if_user_#{user.id}")
    end
  end

  def unless_user(user, tag = :div, &block)
    if user
      content_tag(tag, capture(&block), :class => "hide_if_user_#{user.id}")
    else
      content_tag(tag, capture(&block))
    end
  end

  def if_administrator(tag = :div, &block)
    content_tag(tag, capture(&block), :class => "hide_unless_administrator")
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

    if @user
      data[:user] = @user.id.to_json

      unless @user.home_lon.nil? || @user.home_lat.nil?
        data[:user_home] = { :lat => @user.home_lat, :lon => @user.home_lon }
      end
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
