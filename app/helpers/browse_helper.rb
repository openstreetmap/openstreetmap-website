module BrowseHelper
  def link_to_page(page, page_param)
    return link_to(page, page_param => page)
  end
end
