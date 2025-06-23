module NumberedPaginationHelper
  def element_versions_pagination(top_version, active_version: 0, &)
    tag.ul(:class => [
             "pagination pagination-sm",
             "overflow-x-scroll pb-3", # horizontal scrollbar with reserved space below
             "pt-1" # space reserved for focus outlines
           ]) do
      (1..top_version).each do |v|
        concat element_versions_pagination_item(v, **yield(v), :active => v == active_version)
      end
    end
  end

  private

  def element_versions_pagination_item(body, href: nil, title: nil, active: false)
    link_class = "page-link"
    link = link_to body, href, :class => link_class, :title => title
    tag.li link, :class => ["page-item", { "active" => active }]
  end
end
