# frozen_string_literal: true

module NumberedPaginationHelper
  def numbered_pagination(top_page, active_id, active_page: top_page + 1, window_half_size: 50, step_size: 50, &)
    lists = []

    if top_page <= 5
      lists << tag.ul(:class => "pagination pagination-sm mt-1") do
        (1..top_page).each do |page|
          concat numbered_pagination_item(page, **yield(page), :active_id => (active_id if page == active_page))
        end
      end
    else
      start_list_pages = 1..(active_page < 3 ? active_page + 1 : 1)
      end_list_pages = (active_page > top_page - 2 ? active_page - 1 : top_page)..top_page

      middle_list_page_sentinels = [start_list_pages.last, end_list_pages.first]
      middle_list_page_steps = Range.new(*middle_list_page_sentinels).filter { |page| (page % step_size).zero? }
      middle_list_page_window = Range.new([active_page - window_half_size, start_list_pages.last].max,
                                          [active_page + window_half_size, end_list_pages.first].min).to_a
      middle_list_pages_with_sentinels = (middle_list_page_sentinels | middle_list_page_steps | middle_list_page_window).sort
      middle_list_pages_with_sentinels_and_gaps = [middle_list_pages_with_sentinels.first] +
                                                  middle_list_pages_with_sentinels.each_cons(2).flat_map do |previous_page, page|
                                                    page == previous_page + 1 ? [page] : [:gap, page]
                                                  end
      middle_list_pages_with_small_gaps_filled = middle_list_pages_with_sentinels_and_gaps.each_cons(3).map do |previous_page, page, next_page|
        if page == :gap && previous_page != :gap && next_page != :gap && next_page - previous_page == 2
          previous_page + 1
        else
          page
        end
      end
      middle_list_pages = middle_list_pages_with_small_gaps_filled

      lists << tag.ul(:class => "pagination pagination-sm mt-1") do
        start_list_pages.each do |page|
          concat numbered_pagination_item(page, **yield(page), :active_id => (active_id if page == active_page),
                                                               :edge => [false, page == start_list_pages.last],
                                                               :edge_border => true)
        end
      end
      lists << tag.ul(:class => [
                        "pagination pagination-sm",
                        "overflow-x-auto pb-3", # horizontal scrollbar with reserved space below
                        "pt-1 px-1 mx-n1", # space reserved for focus outlines
                        "position-relative" # required for centering when clicking current page links ("Version #n" on pages showing element versions)
                      ]) do
        middle_list_pages.each_with_index do |page, i|
          edge = [i.zero?, i == middle_list_pages.length - 1]
          if page == :gap
            concat numbered_pagination_item("...", :edge => edge)
          else
            concat numbered_pagination_item(page, **yield(page), :active_id => (active_id if page == active_page),
                                                                 :edge => edge)
          end
        end
      end
      lists << tag.ul(:class => "pagination pagination-sm mt-1") do
        end_list_pages.each do |page|
          concat numbered_pagination_item(page, **yield(page), :active_id => (active_id if page == active_page),
                                                               :edge => [page == end_list_pages.first, false],
                                                               :edge_border => true)
        end
      end
    end

    tag.div safe_join(lists), :class => "numbered_pagination d-flex align-items-start"
  end

  private

  def numbered_pagination_item(body, href: nil, active_id: nil, edge: [false, false], edge_border: false, **link_options)
    link_class = ["page-link", { "rounded-start-0" => edge.first,
                                 "border-start-0" => edge.first && !edge_border,
                                 "rounded-end-0" => edge.last,
                                 "border-end-0" => edge.last && !edge_border }]
    link = if href
             link_to body, href, :class => link_class, "aria-current" => ("page" if active_id), **link_options
           else
             tag.span body, :class => link_class
           end
    tag.li link, :id => active_id, :class => ["page-item", { "disabled" => !href, "active" => !!active_id }]
  end
end
