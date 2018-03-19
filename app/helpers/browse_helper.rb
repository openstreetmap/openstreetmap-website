require "cgi"

module BrowseHelper
  def printable_name(object, version = false)
    id = if object.id.is_a?(Array)
           object.id[0]
         else
           object.id
         end
    name = t "printable_name.with_id", :id => id.to_s
    name = t "printable_name.with_version", :id => name, :version => object.version.to_s if version

    # don't look at object tags if redacted, so as to avoid giving
    # away redacted version tag information.
    unless object.redacted?
      locale = I18n.locale.to_s

      locale = locale.sub(/-[^-]+/, "") while locale =~ /-[^-]+/ && !object.tags.include?("name:#{I18n.locale}")

      if object.tags.include? "name:#{locale}"
        name = t "printable_name.with_name_html", :name => content_tag(:bdi, object.tags["name:#{locale}"].to_s), :id => content_tag(:bdi, name)
      elsif object.tags.include? "name"
        name = t "printable_name.with_name_html", :name => content_tag(:bdi, object.tags["name"].to_s), :id => content_tag(:bdi, name)
      elsif object.tags.include? "ref"
        name = t "printable_name.with_name_html", :name => content_tag(:bdi, object.tags["ref"].to_s), :id => content_tag(:bdi, name)
      end
    end

    name
  end

  def link_class(type, object)
    classes = [type]

    if object.redacted?
      classes << "deleted"
    else
      classes += icon_tags(object).flatten.map { |t| h(t) }
      classes << "deleted" unless object.visible?
    end

    classes.join(" ")
  end

  def link_title(object)
    if object.redacted?
      ""
    else
      h(icon_tags(object).map { |k, v| k + "=" + v }.to_sentence)
    end
  end

  def link_follow(object)
    "nofollow" if object.tags.empty?
  end

  def format_key(key)
    if url = wiki_link("key", key)
      link_to h(key), url, :title => t("browse.tag_details.wiki_link.key", :key => key)
    else
      h(key)
    end
  end

  def format_value(key, value)
    if wp = wikipedia_link(key, value)
      link_to h(wp[:title]), wp[:url], :title => t("browse.tag_details.wikipedia_link", :page => wp[:title])
    elsif wdt = wikidata_links(key, value)
      # IMPORTANT: Note that wikidata_links() returns an array of hashes, unlike for example wikipedia_link(),
      # which just returns one such hash.
      wdt = wdt.map do |w|
        link_to(w[:title], w[:url], :title => t("browse.tag_details.wikidata_link", :page => w[:title].strip))
      end
      safe_join(wdt, ";")
    elsif url = wiki_link("tag", "#{key}=#{value}")
      link_to h(value), url, :title => t("browse.tag_details.wiki_link.tag", :key => key, :value => value)
    elsif url = telephone_link(key, value)
      link_to h(value), url, :title => t("browse.tag_details.telephone_link", :phone_number => value)
    elsif colour_value = colour_preview(key, value)
      content_tag(:span, "", :class => "colour-preview-box", :style => "background-color:#{colour_value}", :title => t("browse.tag_details.colour_preview", :colour_value => colour_value)) + colour_value
    else
      linkify h(value)
    end
  end

  def type_and_paginated_count(type, pages)
    if pages.page_count == 1
      t "browse.changeset.#{type}",
        :count => pages.item_count
    else
      t "browse.changeset.#{type}_paginated",
        :x => pages.current_page.first_item,
        :y => pages.current_page.last_item,
        :count => pages.item_count
    end
  end

  private

  ICON_TAGS = %w[aeroway amenity barrier building highway historic landuse leisure man_made natural railway shop tourism waterway].freeze

  def icon_tags(object)
    object.tags.find_all { |k, _v| ICON_TAGS.include? k }.sort
  end

  def wiki_link(type, lookup)
    locale = I18n.locale.to_s

    # update-wiki-pages does s/ /_/g on keys before saving them, we
    # have to replace spaces with underscore so we'll link
    # e.g. `source=Isle of Man Government aerial imagery (2001)' to
    # the correct page.
    lookup_us = lookup.tr(" ", "_")

    if page = WIKI_PAGES.dig(locale, type, lookup_us)
      url = "https://wiki.openstreetmap.org/wiki/#{page}?uselang=#{locale}"
    elsif page = WIKI_PAGES.dig("en", type, lookup_us)
      url = "https://wiki.openstreetmap.org/wiki/#{page}?uselang=#{locale}"
    end

    url
  end

  def wikipedia_link(key, value)
    # Some k/v's are wikipedia=http://en.wikipedia.org/wiki/Full%20URL
    return nil if value =~ %r{^https?://}

    if key == "wikipedia"
      # This regex should match Wikipedia language codes, everything
      # from de to zh-classical
      lang = if value =~ /^([a-z-]{2,12}):(.+)$/i
               # Value is <lang>:<title> so split it up
               # Note that value is always left as-is, see: https://trac.openstreetmap.org/ticket/4315
               Regexp.last_match(1)
             else
               # Value is <title> so default to English Wikipedia
               "en"
             end
    elsif key =~ /^wikipedia:(\S+)$/
      # Language is in the key, so assume value is the title
      lang = Regexp.last_match(1)
    else
      # Not a wikipedia key!
      return nil
    end

    if value =~ /^([^#]*)#(.*)/
      # Contains a reference to a section of the wikipedia article
      # Must break it up to correctly build the url
      value = Regexp.last_match(1)
      section = "#" + Regexp.last_match(2)
      encoded_section = "#" + CGI.escape(Regexp.last_match(2).gsub(/ +/, "_")).tr("%", ".")
    else
      section = ""
      encoded_section = ""
    end

    {
      :url => "https://#{lang}.wikipedia.org/wiki/#{value}?uselang=#{I18n.locale}#{encoded_section}",
      :title => value + section
    }
  end

  def wikidata_links(key, value)
    # The simple wikidata-tag (this is limited to only one value)
    if key == "wikidata" && value =~ /^[Qq][1-9][0-9]*$/
      return [{
        :url => "//www.wikidata.org/wiki/#{value}?uselang=#{I18n.locale}",
        :title => value
      }]
    # Key has to be one of the accepted wikidata-tags
    elsif key =~ /(architect|artist|brand|name:etymology|network|operator|subject):wikidata/ &&
          # Value has to be a semicolon-separated list of wikidata-IDs (whitespaces allowed before and after semicolons)
          value =~ /^[Qq][1-9][0-9]*(\s*;\s*[Qq][1-9][0-9]*)*$/
      # Splitting at every semicolon to get a separate hash for each wikidata-ID
      return value.split(";").map do |id|
        { :title => id, :url => "//www.wikidata.org/wiki/#{id.strip}?uselang=#{I18n.locale}" }
      end
    end
    nil
  end

  def telephone_link(_key, value)
    # does it look like a phone number? eg "+1 (234) 567-8901 " ?
    return nil unless value =~ %r{^\s*\+[\d\s\(\)/\.-]{6,25}\s*$}

    # remove all whitespace instead of encoding it http://tools.ietf.org/html/rfc3966#section-5.1.1
    # "+1 (234) 567-8901 " -> "+1(234)567-8901"
    value_no_whitespace = value.gsub(/\s+/, "")

    "tel:#{value_no_whitespace}"
  end

  def colour_preview(key, value)
    return nil unless key =~ /^(?>.+:)?colour$/ && !value.nil? # see discussion at https://github.com/openstreetmap/openstreetmap-website/pull/1779
    # does value look like a colour? ( 3 or 6 digit hex code or w3c colour name)
    w3c_colors =
      %w[aliceblue antiquewhite aqua aquamarine azure beige bisque black blanchedalmond blue blueviolet brown burlywood cadetblue chartreuse chocolate coral cornflowerblue cornsilk crimson cyan darkblue darkcyan darkgoldenrod darkgray darkgrey darkgreen darkkhaki darkmagenta darkolivegreen darkorange darkorchid darkred darksalmon darkseagreen darkslateblue darkslategray
         darkslategrey darkturquoise darkviolet deeppink deepskyblue dimgray dimgrey dodgerblue firebrick floralwhite forestgreen fuchsia gainsboro ghostwhite gold goldenrod gray grey green greenyellow honeydew hotpink indianred indigo ivory khaki lavender lavenderblush lawngreen lemonchiffon lightblue lightcoral lightcyan lightgoldenrodyellow lightgray lightgrey lightgreen
         lightpink lightsalmon lightseagreen lightskyblue lightslategray lightslategrey lightsteelblue lightyellow lime limegreen linen magenta maroon mediumaquamarine mediumblue mediumorchid mediumpurple mediumseagreen mediumslateblue mediumspringgreen mediumturquoise mediumvioletred midnightblue mintcream mistyrose moccasin navajowhite navy oldlace olive olivedrab orange
         orangered orchid palegoldenrod palegreen paleturquoise palevioletred papayawhip peachpuff peru pink plum powderblue purple red rosybrown royalblue saddlebrown salmon sandybrown seagreen seashell sienna silver skyblue slateblue slategray slategrey snow springgreen steelblue tan teal thistle tomato turquoise violet wheat white whitesmoke yellow yellowgreen]
    return nil unless value =~ /^#([0-9a-fA-F]{3}){1,2}$/ || w3c_colors.include?(value.downcase)
    value
  end
end
