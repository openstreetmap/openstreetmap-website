module NumberedPaginationHelper
  def element_versions_pagination(active_version, top_version, window_half_size: 50)
    lists = []

    if top_version <= 5
      lists << tag.ul(:class => "pagination pagination-sm mt-1") do
        (1..top_version).each do |v|
          concat element_versions_pagination_item(v, :href => { :version => v },
                                                     :active => v == active_version)
        end
      end
    else
      start_list_version_from = 1
      start_list_version_to = active_version < 3 ? active_version + 1 : 1
      end_list_version_from = active_version > top_version - 2 ? active_version - 1 : top_version
      end_list_version_to = top_version
      middle_list_version_from = [active_version - window_half_size, start_list_version_to + 1].max
      middle_list_version_to = [active_version + window_half_size, end_list_version_from - 1].min

      lists << tag.ul(:id => "versions-navigation-list-start",
                      :class => "pagination pagination-sm mt-1") do
        (start_list_version_from..start_list_version_to).each do |v|
          concat element_versions_pagination_item(v, :href => { :version => v },
                                                     :active => v == active_version,
                                                     :last_item => v == start_list_version_to,
                                                     :edge_item_border => true)
        end
      end
      lists << tag.ul(:id => "versions-navigation-list-scrollable",
                      :class => [
                        "pagination pagination-sm",
                        "overflow-x-scroll pb-3", # horizontal scrollbar with reserved space below
                        "pt-1 px-1 mx-n1", # space reserved for focus outlines
                        "position-relative" # required for centering when clicking "Version #n"
                      ]) do
        concat element_versions_pagination_item("...", :first_item => true) if middle_list_version_from > start_list_version_to + 1
        (middle_list_version_from..middle_list_version_to).each do |v|
          concat element_versions_pagination_item(v, :href => { :version => v },
                                                     :active => v == active_version,
                                                     :first_item => v == start_list_version_to + 1,
                                                     :last_item => v == end_list_version_from - 1)
        end
        concat element_versions_pagination_item("...", :last_item => true) if middle_list_version_to < end_list_version_from - 1
      end
      lists << tag.ul(:id => "versions-navigation-list-end",
                      :class => "pagination pagination-sm mt-1") do
        (end_list_version_from..end_list_version_to).each do |v|
          concat element_versions_pagination_item(v, :href => { :version => v },
                                                     :active => v == active_version,
                                                     :first_item => v == end_list_version_from,
                                                     :edge_item_border => true)
        end
      end
    end

    tag.div safe_join(lists), :class => "d-flex align-items-start"
  end

  def element_versions_pagination_item(body, href: nil, active: false, first_item: false, last_item: false, edge_item_border: false)
    link_class = ["page-link", { "rounded-start-0" => first_item,
                                 "border-start-0" => first_item && !edge_item_border,
                                 "rounded-end-0" => last_item,
                                 "border-end-0" => last_item && !edge_item_border }]
    link = if href
             link_to body, href, :class => link_class
           else
             tag.span body, :class => link_class
           end
    tag.li link, :id => ("versions-navigation-current-page-item" if active),
                 :class => ["page-item", { "disabled" => !href, "active" => active }]
  end
end
