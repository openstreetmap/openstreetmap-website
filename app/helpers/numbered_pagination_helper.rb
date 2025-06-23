module NumberedPaginationHelper
  def element_versions_pagination(top_version, active_version: 0, &)
    lists = []

    if top_version <= 5
      lists << tag.ul(:class => "pagination pagination-sm mt-1") do
        (1..top_version).each do |v|
          concat element_versions_pagination_item(v, **yield(v), :active => v == active_version)
        end
      end
    else
      start_list_versions = 1..1
      end_list_versions = top_version..top_version
      middle_list_versions = (start_list_versions.last + 1)..(end_list_versions.first - 1)

      lists << tag.ul(:class => "pagination pagination-sm mt-1") do
        start_list_versions.each do |v|
          concat element_versions_pagination_item(v, **yield(v), :active => v == active_version)
        end
      end
      lists << tag.ul(:class => [
                        "pagination pagination-sm",
                        "overflow-x-scroll pb-3", # horizontal scrollbar with reserved space below
                        "pt-1" # space reserved for focus outlines
                      ]) do
        middle_list_versions.each do |v|
          concat element_versions_pagination_item(v, **yield(v), :active => v == active_version)
        end
      end
      lists << tag.ul(:class => "pagination pagination-sm mt-1") do
        end_list_versions.each do |v|
          concat element_versions_pagination_item(v, **yield(v), :active => v == active_version)
        end
      end
    end

    tag.div safe_join(lists), :class => "d-flex align-items-start"
  end

  private

  def element_versions_pagination_item(body, href: nil, title: nil, active: false)
    link_class = "page-link"
    link = link_to body, href, :class => link_class, :title => title
    tag.li link, :class => ["page-item", { "active" => active }]
  end
end
