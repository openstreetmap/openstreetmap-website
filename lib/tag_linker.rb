# frozen_string_literal: true

module TagLinker
  SECONDARY_WIKI_PREFIX_PATTERN = /[a-z:_-]+:/
  QID_PATTERN = /[Qq][1-9][0-9]*/

  # regex to match all wikipedia locale project identifiers
  WIKIPEDIA_PROJECT_IDENTIFIER_PATTERN = /[a-z]{2,3}(?:-[a-z]{2,3})?|be-tarask|roa-tara|simple|zh-classical|zh-min-nan/

  def self.init(paths)
    @tag2link_dict = build_tag2link_dict(JSON.parse(paths[:tag2link].read)).freeze
    @wiki_pages_dict = YAML.load_file(paths[:wiki_pages]).freeze
  end

  def self.wiki_link(type, title)
    locale = I18n.locale.to_s

    # update-wiki-pages does s/ /_/g on keys before saving them, we
    # have to replace spaces with underscore so we'll link
    # e.g. `source=Isle of Man Government aerial imagery (2001)' to
    # the correct page.
    lookup = title.tr(" ", "_")

    page = @wiki_pages_dict.dig(locale, type, lookup) ||
           @wiki_pages_dict.dig("en", type, lookup)

    url = "https://wiki.openstreetmap.org/wiki/#{page}?uselang=#{locale}" if page

    url
  end

  def self.wikipedia_links(key, value)
    locale = I18n.locale.to_s
    # Some k/v's are wikipedia=http://en.wikipedia.org/wiki/Full%20URL
    return nil if %r{^https?://}.match?(value)

    if key =~ /^(?:#{SECONDARY_WIKI_PREFIX_PATTERN})?wikipedia(?::(#{WIKIPEDIA_PROJECT_IDENTIFIER_PATTERN}))?$/o
      lang = Regexp.last_match(1)
    else
      return nil
    end

    # Value could be a semicolon-separated list of Wikipedia pages
    value.split(";").map do |wiki_value|
      wiki_value = wiki_value.strip

      if wiki_value =~ /^(#{WIKIPEDIA_PROJECT_IDENTIFIER_PATTERN}):(.+)$/oi
        page_lang = Regexp.last_match(1)
        title_section = Regexp.last_match(2)
      else
        page_lang = lang
        return nil unless page_lang

        title_section = wiki_value
      end

      title, section = title_section.split("#", 2).map { |s| ERB::Util.u(s.tr(" ", "_")) }
      url = "https://#{page_lang}.wikipedia.org/wiki/#{title}?uselang=#{locale}"
      url += "##{section}" if section

      { :url => url, :title => wiki_value }
    end
  end

  def self.wikidata_links(key, value)
    locale = I18n.locale.to_s
    # The simple wikidata-tag (this is limited to only one value)
    if key == "wikidata" && value =~ /^#{QID_PATTERN}$/o
      return [{
        :url => "//www.wikidata.org/entity/#{value}?uselang=#{locale}",
        :title => value
      }]
    elsif key =~ /^#{SECONDARY_WIKI_PREFIX_PATTERN}wikidata$/o &&
          # Value has to be a semicolon-separated list of wikidata-IDs (whitespaces allowed before and after semicolons)
          value =~ /^#{QID_PATTERN}(?:\s*;\s*#{QID_PATTERN})*$/o
      # Splitting at every semicolon to get a separate hash for each wikidata-ID
      return value.split(";").map do |id|
        { :title => id, :url => "//www.wikidata.org/entity/#{id.strip}?uselang=#{locale}" }
      end
    end
    nil
  end

  def self.wikimedia_commons_link(key, value)
    locale = I18n.locale.to_s
    if key =~ /^(?:#{SECONDARY_WIKI_PREFIX_PATTERN})?wikimedia_commons$/o && value =~ /^(file|category):([^#]+)/i
      namespace = Regexp.last_match(1)
      title = Regexp.last_match(2)
      return {
        :url => "//commons.wikimedia.org/wiki/#{namespace}:#{ERB::Util.u title}?uselang=#{locale}",
        :title => value
      }
    end
    nil
  end

  def self.email_link(key, value)
    # Avoid converting conditional tags into emails, since EMAIL_REGEXP is quite permissive
    return nil unless %w[email contact:email].include? key

    # Does the value look like an email? eg "someone@domain.tld"

    #  Uses Ruby built-in regexp to validate email.
    #  This will not catch certain valid emails containing comments, whitespace characters,
    #  and quoted strings.
    #    (see: https://github.com/ruby/ruby/blob/master/lib/uri/mailto.rb)

    # remove any leading and trailing whitespace
    email = value.strip

    return email if email.match?(URI::MailTo::EMAIL_REGEXP)

    nil
  end

  def self.telephone_links(_key, value)
    # Does it look like a global phone number? eg "+1 (234) 567-8901 "
    # or a list of alternate numbers separated by ;
    #
    # Per RFC 3966, this accepts the visual separators -.() within the number,
    # which are displayed and included in the tel: URL, and accepts whitespace,
    # which is displayed but not included in the tel: URL.
    #  (see: http://tools.ietf.org/html/rfc3966#section-5.1.1)
    #
    # Also accepting / as a visual separator although not given in RFC 3966,
    # because it is used as a visual separator in OSM data in some countries.
    if value.match?(%r{^\s*\+[\d\s()/.-]{6,25}\s*(;\s*\+[\d\s()/.-]{6,25}\s*)*$})
      return value.split(";").map do |phone_number|
        # for display, remove leading and trailing whitespace
        phone_number = phone_number.strip

        # for tel: URL, remove all whitespace
        # "+1 (234) 567-8901 " -> "tel:+1(234)567-8901"
        phone_no_whitespace = phone_number.gsub(/\s+/, "")
        { :phone_number => phone_number, :url => "tel:#{phone_no_whitespace}" }
      end
    end
    nil
  end

  def self.colour_preview(key, value)
    return nil unless key =~ /^(?>.+:)?colour$/ && !value.nil? # see discussion at https://github.com/openstreetmap/openstreetmap-website/pull/1779

    # does value look like a colour? ( 3 or 6 digit hex code or w3c colour name)
    w3c_colors =
      %w[aliceblue antiquewhite aqua aquamarine azure beige bisque black blanchedalmond blue blueviolet brown burlywood cadetblue chartreuse chocolate
         coral cornflowerblue cornsilk crimson cyan darkblue darkcyan darkgoldenrod darkgray darkgrey darkgreen darkkhaki darkmagenta darkolivegreen
         darkorange darkorchid darkred darksalmon darkseagreen darkslateblue darkslategray darkslategrey darkturquoise darkviolet deeppink deepskyblue
         dimgray dimgrey dodgerblue firebrick floralwhite forestgreen fuchsia gainsboro ghostwhite gold goldenrod gray grey green greenyellow honeydew
         hotpink indianred indigo ivory khaki lavender lavenderblush lawngreen lemonchiffon lightblue lightcoral lightcyan lightgoldenrodyellow lightgray
         lightgrey lightgreen lightpink lightsalmon lightseagreen lightskyblue lightslategray lightslategrey lightsteelblue lightyellow lime limegreen
         linen magenta maroon mediumaquamarine mediumblue mediumorchid mediumpurple mediumseagreen mediumslateblue mediumspringgreen mediumturquoise
         mediumvioletred midnightblue mintcream mistyrose moccasin navajowhite navy oldlace olive olivedrab orange orangered orchid palegoldenrod
         palegreen paleturquoise palevioletred papayawhip peachpuff peru pink plum powderblue purple red rosybrown royalblue saddlebrown salmon
         sandybrown seagreen seashell sienna silver skyblue slateblue slategray slategrey snow springgreen steelblue tan teal thistle tomato turquoise
         violet wheat white whitesmoke yellow yellowgreen]
    return nil unless value =~ /^#([0-9a-fA-F]{3}){1,2}$/ || w3c_colors.include?(value.downcase)

    value
  end

  def self.basic_link(key, value)
    hv = ERB::Util.h(value)
    return { :text => Linkify.call(hv) } if %r{\Ahttps?://}.match?(value)

    url_template = @tag2link_dict[key]
    return { :text => Linkify.call(hv) } unless url_template

    link = url_template.gsub("$1", value.sub(/^#/, ""))
    return { :text => Linkify.call(hv) } unless link

    { :text => hv, :url => link, :type => :tag2link_link, :key => key }
  end

  def self.build_tag2link_dict(data)
    data
      # exclude deprecated, third-party, and non-HTTP URLs
      .reject { |item| item["rank"] == "deprecated" || item["source"] == "wikidata:P3303" || !item["url"].match?(%r{\Ahttps?://[^$]}) }
      .group_by { |item| item["key"].sub(/^Key:/, "") }
      .transform_values { |items| choose_best_tag2link_item(items) }
      .compact
      .transform_values { |items| items["url"] }
  end

  def self.choose_best_tag2link_item(items)
    return nil if items.blank?

    return items.first if items.size == 1

    # move preferred to the start of the array
    ranked = items.sort_by { |item| item["rank"] == "preferred" ? 0 : 1 }.uniq { |item| item["url"] }
    top_rank = ranked.first["rank"]
    top_items = ranked.select { |i| i["rank"] == top_rank }

    # if only one top-ranked item, prefer that
    return top_items.first if top_items.size == 1

    grouped = top_items.group_by { |i| i["source"] }
    return nil if grouped.size > 2

    # if both sources have exactly one preferred, prefer osmwiki
    return grouped["osmwiki:P8"]&.first || grouped.values.flatten.first if grouped.all? { |_s, vals| vals.size == 1 }

    # if one source has multiple preferreds and the other has one, prefer the single one
    return grouped.min_by { |_s, vals| vals.size }.last.first if grouped.any? { |_s, vals| vals.size == 1 }

    # exclude any that are ambiguous
    nil
  end
  private_class_method :choose_best_tag2link_item
end
