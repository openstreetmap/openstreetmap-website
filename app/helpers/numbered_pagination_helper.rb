module NumberedPaginationHelper
  def element_versions_pagination(top_version, active_version: top_version + 1, window_half_size: 50, step_size: 50, &)
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

      middle_list_version_sentinels = [start_list_versions.last, end_list_versions.first]
      middle_list_version_steps = Range.new(*middle_list_version_sentinels).filter { |v| (v % step_size).zero? }
      middle_list_version_window = Range.new([active_version - window_half_size, start_list_versions.last].max,
                                             [active_version + window_half_size, end_list_versions.first].min).to_a
      middle_list_versions_with_sentinels = (middle_list_version_sentinels | middle_list_version_steps | middle_list_version_window).sort
      middle_list_versions_with_sentinels_and_gaps = [middle_list_versions_with_sentinels.first] +
                                                     middle_list_versions_with_sentinels.each_cons(2).flat_map do |previous_version, v|
                                                       v == previous_version + 1 ? [v] : [:gap, v]
                                                     end
      middle_list_versions_with_small_gaps_filled = middle_list_versions_with_sentinels_and_gaps.each_cons(3).map do |previous_version, v, next_version|
        if v == :gap && previous_version != :gap && next_version != :gap && next_version - previous_version == 2
          previous_version + 1
        else
          v
        end
      end
      middle_list_versions = middle_list_versions_with_small_gaps_filled

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
        middle_list_versions.each_with_index do |v, i|
          edge = [i.zero?, i == middle_list_versions.length - 1]
          if v == :gap
            concat element_versions_pagination_item("...", :edge => edge)
          else
            concat element_versions_pagination_item(v, **yield(v), :active => v == active_version, :edge => edge)
          end
        end
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
