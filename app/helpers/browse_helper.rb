module BrowseHelper
  def element_icon(type, object)
    selected_icon_data = { :filename => "#{type}.svg", :priority => 1 }

    unless object.redacted?
      target_tags = object.tags.find_all { |k, _v| BROWSE_ICONS.key? k }.sort
      title = target_tags.map { |k, v| "#{k}=#{v}" }.to_sentence unless target_tags.empty?

      target_tags.each do |k, v|
        icon_data = BROWSE_ICONS[k][v] || BROWSE_ICONS[k][:*]
        selected_icon_data = icon_data if icon_data && icon_data[:priority] > selected_icon_data[:priority]
      end
    end

    image_tag "browse/#{selected_icon_data[:filename]}",
              :size => 20,
              :class => ["align-bottom object-fit-none browse-icon", { "browse-icon-invertible" => selected_icon_data[:invert] }],
              :title => title
  end

  def element_single_current_link(type, object)
    link_to object, { :rel => (link_follow(object) if type == "node") } do
      element_strikethrough object do
        printable_element_name object
      end
    end
  end

  def element_list_item(type, object, &)
    tag.li(tag.div(element_icon(type, object) + tag.div(:class => "align-self-center", &), :class => "d-flex gap-1"))
  end

  def element_list_item_with_strikethrough(type, object, &)
    element_list_item type, object do
      element_strikethrough object, &
    end
  end

  def printable_element_name(object)
    id = if object.id.is_a?(Array)
           object.id[0]
         else
           object.id
         end
    name = id.to_s

    # don't look at object tags if redacted, so as to avoid giving
    # away redacted version tag information.
    unless object.redacted?
      feature_name = feature_name(object.tags)
      name = t "printable_name.with_name_html", :name => tag.bdi(feature_name), :id => tag.bdi(id.to_s) if feature_name.present?
    end

    name
  end

  def printable_element_version(object)
    t "printable_name.version", :version => object.version
  end

  def element_strikethrough(object, &)
    if object.redacted? || !object.visible?
      tag.s(&)
    else
      yield
    end
  end

  def link_follow(object)
    "nofollow" if object.tags.empty?
  end

  def sidebar_classic_pagination(pages, page_param)
    max_width_for_default_padding = 35

    width = 0
    pagination_items(pages, {}).each do |(body)|
      width += 2 # padding width
      width += body.length
    end
    link_classes = ["page-link", { "px-1" => width > max_width_for_default_padding }]

    tag.ul :class => "pagination pagination-sm mb-2" do
      pagination_items(pages, {}).each do |body, page_or_class|
        linked = !(page_or_class.is_a? String)
        link = if linked
                 link_to body, url_for(page_param => page_or_class.number), :class => link_classes, **yield(page_or_class)
               else
                 tag.span body, :class => link_classes
               end
        concat tag.li link, :class => ["page-item", { page_or_class => !linked }]
      end
    end
  end

  def element_versions_pagination(active_version, top_version, window_half_size: 50)
    lists = []

    if top_version <= 5
      lists << tag.ul(:class => "pagination pagination-sm mt-1") do
        (1..top_version).each do |v|
          concat element_versions_pagination_item(:version => v, :active => v == active_version)
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
          concat element_versions_pagination_item(:version => v,
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
        concat element_versions_pagination_item(:first_item => true) if middle_list_version_from > start_list_version_to + 1
        (middle_list_version_from..middle_list_version_to).each do |v|
          concat element_versions_pagination_item(:version => v,
                                                  :active => v == active_version,
                                                  :first_item => v == start_list_version_to + 1,
                                                  :last_item => v == end_list_version_from - 1)
        end
        concat element_versions_pagination_item(:last_item => true) if middle_list_version_to < end_list_version_from - 1
      end
      lists << tag.ul(:id => "versions-navigation-list-end",
                      :class => "pagination pagination-sm mt-1") do
        (end_list_version_from..end_list_version_to).each do |v|
          concat element_versions_pagination_item(:version => v,
                                                  :active => v == active_version,
                                                  :first_item => v == end_list_version_from,
                                                  :edge_item_border => true)
        end
      end
    end

    tag.div safe_join(lists), :class => "d-flex align-items-start"
  end

  def element_versions_pagination_item(version: nil, active: false, first_item: false, last_item: false, edge_item_border: false)
    link_class = ["page-link", { "rounded-start-0" => first_item,
                                 "border-start-0" => first_item && !edge_item_border,
                                 "rounded-end-0" => last_item,
                                 "border-end-0" => last_item && !edge_item_border }]
    link = if version
             link_to version, { :version => version }, :class => link_class
           else
             tag.span "...", :class => link_class
           end
    tag.li link, :id => ("versions-navigation-current-page-item" if active),
                 :class => ["page-item", { "disabled" => !version, "active" => active }]
  end

  private

  def feature_name(tags)
    locale_keys = preferred_languages.expand.map { |locale| "name:#{locale}" }

    (locale_keys + %w[name ref addr:housename]).each do |key|
      return tags[key] if tags[key]
    end
    # TODO: Localize format to country of address
    return "#{tags['addr:housenumber']} #{tags['addr:street']}" if tags["addr:housenumber"] && tags["addr:street"]

    nil
  end
end
