module ApplicationHelper
  require 'rexml/document'

  def linkify(text)
    if text.html_safe?
      Rinku.auto_link(text, :urls, tag_options(:rel => "nofollow")).html_safe
    else
      Rinku.auto_link(text, :urls, tag_options(:rel => "nofollow"))
    end
  end

  def rss_link_to(*args)
    return link_to(image_tag("RSS.gif", :size => "16x16", :border => 0), Hash[*args], { :class => "rsssmall" });
  end

  def atom_link_to(*args)
    return link_to(image_tag("RSS.gif", :size => "16x16", :border => 0), Hash[*args], { :class => "rsssmall" });
  end

  def style_rules
    css = ""

    css << ".hidden { display: none }";
    css << ".hide_unless_logged_in { display: none }" unless @user;
    css << ".hide_if_logged_in { display: none }" if @user;
    css << ".hide_if_user_#{@user.id} { display: none }" if @user;
    css << ".show_if_user_#{@user.id} { display: inline }" if @user;
    css << ".hide_unless_administrator { display: none }" unless @user and @user.administrator?;

    return content_tag(:style, css, :type => "text/css")
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

  def preferred_editor
    if params[:editor]
      params[:editor]
    elsif @user and @user.preferred_editor
      @user.preferred_editor
    else
      DEFAULT_EDITOR
    end
  end

  def scale_to_zoom(scale)
    Math.log(360.0 / (scale.to_f * 512.0)) / Math.log(2.0)
  end

  def richtext_area(object_name, method, options = {})
    id = "#{object_name.to_s}_#{method.to_s}"
    format = options.delete(:format) || "markdown"

    content_tag(:div, :id => "#{id}_container", :class => "richtext_container") do
      output_buffer << content_tag(:div, :id => "#{id}_content", :class => "richtext_content") do
        output_buffer << text_area(object_name, method, options.merge("data-preview-url" => preview_url(:format => format)))
        output_buffer << content_tag(:div, "", :id => "#{id}_preview", :class => "richtext_preview")
      end

      output_buffer << content_tag(:div, :id => "#{id}_help", :class => "richtext_help") do
        output_buffer << render("site/#{format}_help")
        output_buffer << submit_tag(I18n.t("site.richtext_area.edit"), :id => "#{id}_doedit", :class => "richtext_doedit", :disabled => true)
        output_buffer << submit_tag(I18n.t("site.richtext_area.preview"), :id => "#{id}_dopreview", :class => "richtext_dopreview")
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

  def note_author(object, link_options = {})
    if object.author.nil?
      h(object.author_name)
    else
      link_to h(object.author_name), link_options.merge({:controller => "user", :action => "view", :display_name => object.author_name})
    end
  end
end
