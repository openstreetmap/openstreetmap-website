module BrowseHelper
  def link_to_page(page, page_param)
    return link_to(page, page_param => page)
  end

  def printable_name(object, version=false)
    if object.id.is_a?(Array)
      id = object.id[0]
    else
      id = object.id
    end
    name = t 'printable_name.with_id', :id => id.to_s
    if version
      name = t 'printable_name.with_version', :id => name, :version => object.version.to_s
    end
    if object.tags.include? "name:#{I18n.locale}"
      name = t 'printable_name.with_name',  :name => object.tags["name:#{I18n.locale}"].to_s, :id => name
    elsif object.tags.include? 'name'
      name = t 'printable_name.with_name',  :name => object.tags['name'].to_s, :id => name
    end
    return name
  end

  def link_class(type, object)
    return type + " " + h(icon_tags(object).join(' ')) + (object.visible == false ? ' deleted' : '')
  end

  def link_title(object)
    return h(icon_tags(object).map { |k,v| k + '=' + v }.to_sentence)
  end

  def format_key(key)
    if url = wiki_link("key", key)
      link_to h(key), url, :title => t('browse.tag_details.wiki_link.key', :key => key)
    else
      h(key)
    end
  end

  def format_value(key, value)
    if wp = wikipedia_link(key, value)
      link_to h(wp[:title]), wp[:url], :title => t('browse.tag_details.wikipedia_link', :page => wp[:title])
    elsif url = wiki_link("tag", "#{key}=#{value}")
      link_to h(value), url, :title => t('browse.tag_details.wiki_link.tag', :key => key, :value => value)
    else
      linkify h(value)
    end
  end

private

  ICON_TAGS = [ 
    "aeroway", "amenity", "barrier", "building", "highway", "historic", "landuse",
    "leisure", "man_made", "natural", "railway", "shop", "tourism", "waterway"
  ]

  def icon_tags(object)
    object.tags.find_all { |k,v| ICON_TAGS.include? k }
  end

  def wiki_link(type, lookup)
    locale = I18n.locale.to_s

    # update-wiki-pages does s/ /_/g on keys before saving them, we
    # have to replace spaces with underscore so we'll link
    # e.g. `source=Isle of Man Government aerial imagery (2001)' to
    # the correct page.
    lookup_us = lookup.tr(" ", "_")

    if page = WIKI_PAGES[locale][type][lookup_us] rescue nil
      url = "http://wiki.openstreetmap.org/wiki/#{page}?uselang=#{locale}"
    elsif page = WIKI_PAGES["en"][type][lookup_us] rescue nil
      url = "http://wiki.openstreetmap.org/wiki/#{page}?uselang=#{locale}"
    end

    return url
  end

  def wikipedia_link(key, value)
    # Some k/v's are wikipedia=http://en.wikipedia.org/wiki/Full%20URL
    return nil if value =~ /^https?:\/\//

    if key == "wikipedia"
      # This regex should match Wikipedia language codes, everything
      # from de to zh-classical
      if value =~ /^([a-z-]{2,12}):(.+)$/
        # Value is <lang>:<title> so split it up
        lang  = $1
        value = $2
      else
        # Value is <title> so default to English Wikipedia
        lang = 'en'
      end
    elsif key =~ /^wikipedia:(\S+)$/
      # Language is in the key, so assume value is a simple title
      lang = $1
    else
      # Not a wikipedia key!
      return nil
    end

    return {
      :url => "http://#{lang}.wikipedia.org/wiki/#{value}?uselang=#{I18n.locale}",
      :title => value
    }
  end
end
