module BrowseHelper
  def link_to_page(page, page_param)
    return link_to(page, page_param => page)
  end
  
  def printable_name(object, version=false)
    name = t 'printable_name.with_id', :id => object.id.to_s
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

  def wiki_link(type, key, tag)
    wiki_data = YAML.load_file("#{RAILS_ROOT}/config/wiki-tag-and-key-description.yml")
    my_locale = I18n.locale.to_s

    if type == "key"
      ret = key
      lookup = key
    else
      ret = tag
      lookup = key + "=" + tag
    end

    # Try our native language
    has_primary = wiki_data[my_locale][type][lookup] rescue false
    if has_primary
      ret = wikify(type, key, tag, lookup, wiki_data[my_locale][type][lookup])
    else
      # Fall back on English
      has_fallback = wiki_data["en"][type][lookup] rescue false
      if has_fallback
        ret = wikify(type, key, tag, lookup, wiki_data["en"][type][lookup])
      end
    end

    return ret
  end

  def wikify(type, key, tag, text, wiki)
    my_locale = I18n.locale
    url = "http://wiki.openstreetmap.org/index.php?title=#{wiki}&uselang=#{my_locale}"
    
    if type == "key"
      return '<a href="' + url + '" title="' + h(t('browse.tag_details.wiki_link.key', :key => key)) + '">' + h(text) + '</a>'
    else
      return '<a href="' + url + '" title="' + h(t('browse.tag_details.wiki_link.tag', :key => key, :value => tag)) + '">' + h(tag) + '</a>'
    end
  end
end
