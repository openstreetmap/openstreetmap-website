module ApplicationHelper
  require 'rexml/document'

  def sanitize(text)
    Sanitize.clean(text, Sanitize::Config::OSM)
  end

  def htmlize(text)
    return linkify(sanitize(simple_format(text)))
  end

  def linkify(text)
    return auto_link(text, :link => :urls, :html => { :rel => "nofollow" })
  end

  def html_escape_unicode(text)
    chars = ActiveSupport::Multibyte::Chars.u_unpack(text).map do |c|
      c < 127 ? c.chr : "&##{c.to_s};"
    end

    return chars.join("")
  end

  def rss_link_to(*args)
    return link_to(image_tag("RSS.gif", :size => "16x16", :border => 0), Hash[*args], { :class => "rsssmall" });
  end

  def atom_link_to(*args)
    return link_to(image_tag("RSS.gif", :size => "16x16", :border => 0), Hash[*args], { :class => "rsssmall" });
  end

  def javascript_strings
    js = ""

    js << "<script type='text/javascript'>\n"
    js << "i18n_strings = new Array();\n"
    js << javascript_strings_for_key("javascripts")
    js << "</script>\n"

    return js
  end

  def style_rules
    css = ""

    css << ".hidden { display: none }";
    css << ".hide_unless_logged_in { display: none }" unless @user;
    css << ".hide_if_logged_in { display: none }" if @user;
    css << ".hide_if_user_#{@user.id} { display: none }" if @user;
    css << ".show_if_user_#{@user.id} { display: inline }" if @user;
    css << ".hide_unless_administrator { display: none }" unless @user and @user.administrator?;

    return content_tag(:style, css)
  end

  def if_logged_in(tag = :div, &block)
    concat(content_tag(tag, capture(&block), :class => "hide_unless_logged_in"))
  end

  def if_not_logged_in(tag = :div, &block)
    concat(content_tag(tag, capture(&block), :class => "hide_if_logged_in"))
  end

  def if_user(user, tag = :div, &block)
    if user
      concat(content_tag(tag, capture(&block), :class => "hidden show_if_user_#{user.id}"))
    end
  end

  def unless_user(user, tag = :div, &block)
    if user
      concat(content_tag(tag, capture(&block), :class => "hide_if_user_#{user.id}"))
    else
      concat(content_tag(tag, capture(&block)))
    end
  end

  def if_administrator(tag = :div, &block)
    concat(content_tag(tag, capture(&block), :class => "hide_unless_administrator"))
  end

  def describe_location(lat, lon, zoom = nil, language = nil)
    zoom = zoom || 14
    language = language || request.user_preferred_languages.join(',')
    url = "http://nominatim.openstreetmap.org/reverse?lat=#{lat}&lon=#{lon}&zoom=#{zoom}&accept-language=#{language}"

    begin
      response = Timeout::timeout(4) do
        REXML::Document.new(Net::HTTP.get(URI.parse(url)))
      end
    rescue Exception
      response = nil
    end

    if response and result = response.get_text("reversegeocode/result")
      result.to_s
    else
      "#{number_with_precision(lat, :precision => 3)}, #{number_with_precision(lon, :precision => 3)}"
    end
  end

  def user_image(user, options = {})
    options[:class] ||= "user_image"

    if user.image
      image_tag url_for_file_column(user, "image"), options
    else
      image_tag "anon_large.png", options
    end
  end

  def user_thumbnail(user, options = {})
    options[:class] ||= "user_thumbnail"

    if user.image
      image_tag url_for_file_column(user, "image"), options
    else
      image_tag "anon_small.png", options
    end
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

private

  def javascript_strings_for_key(key)
    js = ""
    value = I18n.t(key, :locale => "en")

    if value.is_a?(String)
      js << "i18n_strings['#{key}'] = '" << escape_javascript(t(key)) << "';\n"
    else
      value.each_key do |k|
        js << javascript_strings_for_key("#{key}.#{k}")
      end
    end

    return js
  end
end
