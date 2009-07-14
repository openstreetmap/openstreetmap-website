module ApplicationHelper
  def htmlize(text)
    return sanitize(auto_link(simple_format(text), :urls))
  end

  def rss_link_to(*args)
    return link_to(image_tag("RSS.gif", :size => "16x16", :border => 0), Hash[*args], { :class => "rsssmall" });
  end

  def atom_link_to(*args)
    return link_to(image_tag("RSS.gif", :size => "16x16", :border => 0), Hash[*args], { :class => "rsssmall" });
  end
end
