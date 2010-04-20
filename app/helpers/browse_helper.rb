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

  def format_key(key)
    if url = wiki_link("key", key)
      link_to h(key), url, :title => t('browse.tag_details.wiki_link.key', :key => key)
    else
      h(key)
    end
  end

  def format_value(key, value)
    if url = wiki_link("tag", "#{key}=#{value}")
      link_to h(value), url, :title => t('browse.tag_details.wiki_link.tag', :key => key, :value => value)
    else
      linkify h(value)
    end
  end

private

  def wiki_link(type, lookup)
    wiki_data = YAML.load_file("#{RAILS_ROOT}/config/wiki-tag-and-key-description.yml")
    locale = I18n.locale.to_s

    if page = wiki_data[locale][type][lookup] rescue nil
      url = "http://wiki.openstreetmap.org/wiki/#{page}?uselang=#{locale}"
    elsif page = wiki_data["en"][type][lookup] rescue nil
      url = "http://wiki.openstreetmap.org/wiki/#{page}?uselang=#{locale}"
    end

    return url
  end
end
