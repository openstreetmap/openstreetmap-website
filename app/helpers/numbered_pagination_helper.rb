module NumberedPaginationHelper
  def element_versions_pagination(top_version, active_version: top_version + 1, window_half_size: 50, &)
    lists = []

    if top_version <= 5
      lists << tag.ul(:class => "pagination pagination-sm mt-1") do
        (1..top_version).each do |v|
          concat element_versions_pagination_item(v, **yield(v), :active => v == active_version)
        end
      end
    else
      start_list_versions = 1..(active_version < 3 ? active_version + 1 : 1)
      end_list_versions = (active_version > top_version - 2 ? active_version - 1 : top_version)..top_version
      middle_list_versions = Range.new([active_version - window_half_size, start_list_versions.last + 1].max,
                                       [active_version + window_half_size, end_list_versions.first - 1].min)

      lists << tag.ul(:id => "versions-navigation-list-start",
                      :class => "pagination pagination-sm mt-1") do
        start_list_versions.each do |v|
          concat element_versions_pagination_item(v, **yield(v), :active => v == active_version,
                                                                 :edge => [false, v == start_list_versions.last],
                                                                 :edge_border => true)
        end
      end
      lists << tag.ul(:id => "versions-navigation-list-middle",
                      :class => [
                        "pagination pagination-sm",
                        "overflow-x-scroll pb-3", # horizontal scrollbar with reserved space below
                        "pt-1 px-1 mx-n1", # space reserved for focus outlines
                        "position-relative" # required for centering when clicking "Version #n"
                      ]) do
        concat element_versions_pagination_item("...", :edge => [true, false]) if middle_list_versions.first > start_list_versions.last + 1
        middle_list_versions.each do |v|
          concat element_versions_pagination_item(v, **yield(v), :active => v == active_version,
                                                                 :edge => [v == start_list_versions.last + 1,
                                                                           v == end_list_versions.first - 1])
        end
        concat element_versions_pagination_item("...", :edge => [false, true]) if middle_list_versions.last < end_list_versions.first - 1
      end
      lists << tag.ul(:id => "versions-navigation-list-end",
                      :class => "pagination pagination-sm mt-1") do
        end_list_versions.each do |v|
          concat element_versions_pagination_item(v, **yield(v), :active => v == active_version,
                                                                 :edge => [v == end_list_versions.first, false],
                                                                 :edge_border => true)
        end
      end
    end

    tag.div safe_join(lists), :class => "d-flex align-items-start"
  end

  private

  def element_versions_pagination_item(body, href: nil, title: nil, active: false, edge: [false, false], edge_border: false)
    link_class = ["page-link", { "rounded-start-0" => edge.first,
                                 "border-start-0" => edge.first && !edge_border,
                                 "rounded-end-0" => edge.last,
                                 "border-end-0" => edge.last && !edge_border }]
    link = if href
             link_to body, href, :class => link_class, :title => title
           else
             tag.span body, :class => link_class
           end
    tag.li link, :id => ("versions-navigation-active-page-item" if active),
                 :class => ["page-item", { "disabled" => !href, "active" => active }]
  end
end
