module PaginationHelper
  def pagination_item(params, title, &block)
    link_class = "page-link icon-link text-center"
    page_link_content = capture(&block)
    if params
      page_link = link_to page_link_content, params, :class => link_class, :title => title
      tag.li page_link, :class => "page-item d-flex"
    else
      page_link = tag.span page_link_content, :class => link_class
      tag.li page_link, :class => "page-item d-flex disabled"
    end
  end
end
