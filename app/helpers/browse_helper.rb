module BrowseHelper
  def link_to_page(page, page_param)
    return link_to(page, page_param => page)
  end
  
  def printable_name(object, version=false)
    name = object.id.to_s
    if version
      name = "#{name}, v#{object.version.to_s}"
    end
    if object.tags.include? 'name'
      name = "#{object.tags['name'].to_s} (#{name})"
    end
    return name
  end
end
