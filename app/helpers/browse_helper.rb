module BrowseHelper
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

    # don't look at object tags if redacted, so as to avoid giving
    # away redacted version tag information.
    unless object.redacted?
      locale = I18n.locale.to_s

      while locale =~ /-[^-]+/ and not object.tags.include? "name:#{I18n.locale}"
        locale = locale.sub(/-[^-]+/, "")
      end

      if object.tags.include? "name:#{locale}"
        name = t 'printable_name.with_name_html', :name => content_tag(:bdi, object.tags["name:#{locale}"].to_s ), :id => content_tag(:bdi, name)
      elsif object.tags.include? 'name'
        name = t 'printable_name.with_name_html', :name => content_tag(:bdi, object.tags['name'].to_s ), :id => content_tag(:bdi, name)
      end
    end

    name
  end

  def link_class(type, object)
    classes = [ type ]

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
      h(icon_tags(object).map { |k,v| k + '=' + v }.to_sentence)
    end
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
    elsif url = telephone_link(key, value)
      link_to h(value), url, :title => t('browse.tag_details.telephone_link', :phone_number => value)
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
      if value =~ /^([a-z-]{2,12}):(.+)$/i
        # Value is <lang>:<title> so split it up
        # Note that value is always left as-is, see: https://trac.openstreetmap.org/ticket/4315
        lang  = $1
      else
        # Value is <title> so default to English Wikipedia
        lang = 'en'
      end
    elsif key =~ /^wikipedia:(\S+)$/
      # Language is in the key, so assume value is the title
      lang = $1
    else
      # Not a wikipedia key!
      return nil
    end

    if value =~ /^([^#]*)(#.*)/ then
      # Contains a reference to a section of the wikipedia article
      # Must break it up to correctly build the url
      value = $1
      section = $2
    else
      section = ""
    end

    return {
      :url => "http://#{lang}.wikipedia.org/wiki/#{value}?uselang=#{I18n.locale}#{section}",
      :title => value + section
    }
  end

  def telephone_link(key, value)
    # does it look like a phone number? eg "+1 (234) 567-8901 " ?
    return nil unless value =~ /^\s*\+[\d\s\(\)\/\.-]{6,25}\s*$/

    # remove all whitespace instead of encoding it http://tools.ietf.org/html/rfc3966#section-5.1.1
    # "+1 (234) 567-8901 " -> "+1(234)567-8901"
    valueNoWhitespace = value.gsub(/\s+/, '')

    return "tel:#{valueNoWhitespace}"
  end
end
