module BrowseTagsHelper
  # https://wiki.openstreetmap.org/wiki/Key:wikipedia#Secondary_Wikipedia_links
  # https://wiki.openstreetmap.org/wiki/Key:wikidata#Secondary_Wikidata_links
  SECONDARY_WIKI_PREFIXES = "architect|artist|brand|buried|flag|genus|manufacturer|model|name:etymology|network|operator|species|subject".freeze

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
    elsif wmc = wikimedia_commons_link(key, value)
      link_to h(wmc[:title]), wmc[:url], :title => t("browse.tag_details.wikimedia_commons_link", :page => wmc[:title])
    elsif url = wiki_link("tag", "#{key}=#{value}")
      link_to h(value), url, :title => t("browse.tag_details.wiki_link.tag", :key => key, :value => value)
    elsif email = email_link(key, value)
      mail_to(email, :title => t("browse.tag_details.email_link", :email => email))
    elsif phones = telephone_links(key, value)
      # similarly, telephone_links() returns an array of phone numbers
      phones = phones.map do |p|
        link_to(h(p[:phone_number]), p[:url], :title => t("browse.tag_details.telephone_link", :phone_number => p[:phone_number]))
      end
      safe_join(phones, "; ")
    elsif colour_value = colour_preview(key, value)
      svg = tag.svg :width => 14, :height => 14, :class => "float-end m-1" do
        concat tag.title t("browse.tag_details.colour_preview", :colour_value => colour_value)
        concat tag.rect :x => 0.5, :y => 0.5, :width => 13, :height => 13, :fill => colour_value, :stroke => "#2222"
      end
      svg + colour_value
    else
      safe_join(value.split(";", -1).map { |x| linkify(h(x)) }, ";")
    end
  end

  private

  def wiki_link(type, lookup)
    locale = I18n.locale.to_s

    # update-wiki-pages does s/ /_/g on keys before saving them, we
    # have to replace spaces with underscore so we'll link
    # e.g. `source=Isle of Man Government aerial imagery (2001)' to
    # the correct page.
    lookup_us = lookup.tr(" ", "_")

    page = WIKI_PAGES.dig(locale, type, lookup_us) ||
           WIKI_PAGES.dig("en", type, lookup_us)

    url = "https://wiki.openstreetmap.org/wiki/#{page}?uselang=#{locale}" if page

    url
  end

  def wikipedia_link(key, value)
    # Some k/v's are wikipedia=http://en.wikipedia.org/wiki/Full%20URL
    return nil if %r{^https?://}.match?(value)

    case key
    when "wikipedia", /^(#{SECONDARY_WIKI_PREFIXES}):wikipedia/o
      lang = "en"
    when /^wikipedia:(\S+)$/
      lang = Regexp.last_match(1)
    else
      return nil
    end

    # This regex should match Wikipedia language codes, everything
    # from de to zh-classical
    if value =~ /^([a-z-]{2,12}):(.+)$/i
      lang = Regexp.last_match(1)
      title_section = Regexp.last_match(2)
    else
      title_section = value
    end

    title, section = title_section.split("#", 2)
    url = "https://#{lang}.wikipedia.org/wiki/#{wiki_encode(title)}?uselang=#{I18n.locale}"
    url += "##{wiki_encode(section)}" if section

    { :url => url, :title => value }
  end

  def wiki_encode(s)
    u s.tr(" ", "_")
  end

  def wikidata_links(key, value)
    # The simple wikidata-tag (this is limited to only one value)
    if key == "wikidata" && value =~ /^[Qq][1-9][0-9]*$/
      return [{
        :url => "//www.wikidata.org/entity/#{value}?uselang=#{I18n.locale}",
        :title => value
      }]
    # Key has to be one of the accepted wikidata-tags
    elsif key =~ /(#{SECONDARY_WIKI_PREFIXES}):wikidata/o &&
          # Value has to be a semicolon-separated list of wikidata-IDs (whitespaces allowed before and after semicolons)
          value =~ /^[Qq][1-9][0-9]*(\s*;\s*[Qq][1-9][0-9]*)*$/
      # Splitting at every semicolon to get a separate hash for each wikidata-ID
      return value.split(";").map do |id|
        { :title => id, :url => "//www.wikidata.org/entity/#{id.strip}?uselang=#{I18n.locale}" }
      end
    end
    nil
  end

  def wikimedia_commons_link(key, value)
    if key == "wikimedia_commons" && value =~ /^(file|category):([^#]+)/i
      namespace = Regexp.last_match(1)
      title = Regexp.last_match(2)
      return {
        :url => "//commons.wikimedia.org/wiki/#{namespace}:#{u title}?uselang=#{I18n.locale}",
        :title => value
      }
    end
    nil
  end

  def email_link(key, value)
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

  def telephone_links(_key, value)
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

  def colour_preview(key, value)
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
end
