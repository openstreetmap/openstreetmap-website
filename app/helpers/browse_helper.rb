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

  def element_versions_pagination(displayed_version, top_version)
    lists = []

    if top_version <= 5
      lists << tag.ul(:class => "pagination pagination-sm") do
        concat element_versions_pagination_item(1, 1 == displayed_version)
      end
    else
      start_bound = displayed_version < 3 ? displayed_version + 2 : 2
      end_bound = displayed_version > top_version - 2 ? displayed_version - 1 : top_version

      lists << tag.ul(:id => "versions-navigation-pinned-start",
                      :class => "pagination pagination-sm z-1") do
        (1...start_bound).each do |v|
          concat element_versions_pagination_item(v, v == displayed_version, { "rounded-end-0" => v == start_bound - 1 })
        end
      end
      lists << tag.ul(:id => "versions-navigation-scrollable",
                      :class => "pagination pagination-sm pb-3 overflow-x-scroll position-relative z-0") do
        (start_bound...end_bound).each do |v|
          concat element_versions_pagination_item(v, v == displayed_version, { "rounded-0" => true,
                                                                               "border-start-0" => v == start_bound,
                                                                               "border-end-0" => v == end_bound - 1 })
        end
      end
      lists << tag.ul(:id => "versions-navigation-pinned-end",
                      :class => "pagination pagination-sm z-1") do
        (end_bound..top_version).each do |v|
          concat element_versions_pagination_item(v, v == displayed_version, { "rounded-start-0" => v == end_bound })
        end
      end
    end

    tag.div safe_join(lists), :class => "d-flex align-items-start"
  end

  def element_versions_pagination_item(version, active, extra_classes = {})
    link = if active
             tag.span version, :class => ["page-link", extra_classes]
           else
             link_to version, { :version => version }, :class => ["page-link", extra_classes]
           end
    tag.li link, :id => ("versions-navigation-current-page-link" if active),
                 :class => ["page-item", { "active" => active }]
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
