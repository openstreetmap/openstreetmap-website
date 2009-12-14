module ApplicationHelper
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

private

  def javascript_strings_for_key(key)
    js = ""
    value = t(key, :locale => "en")

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
