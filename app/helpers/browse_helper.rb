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
      available_locales = Locale.list(name_locales(object))

      locale = available_locales.preferred(preferred_languages, :default => nil)

      if object.tags.include? "name:#{locale}"
        name = t "printable_name.with_name_html", :name => tag.bdi(object.tags["name:#{locale}"].to_s), :id => tag.bdi(name)
      elsif object.tags.include? "name"
        name = t "printable_name.with_name_html", :name => tag.bdi(object.tags["name"].to_s), :id => tag.bdi(name)
      elsif object.tags.include? "ref"
        name = t "printable_name.with_name_html", :name => tag.bdi(object.tags["ref"].to_s), :id => tag.bdi(name)
      end
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

  def type_and_paginated_count(type, pages, selected_page = pages.current_page)
    if pages.page_count == 1
      t ".#{type.pluralize}",
        :count => pages.item_count
    else
      t ".#{type.pluralize}_paginated",
        :x => selected_page.first_item,
        :y => selected_page.last_item,
        :count => pages.item_count
    end
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

  private

  def name_locales(object)
    object.tags.keys.map { |k| Regexp.last_match(1) if k =~ /^name:(.*)$/ }.flatten
  end
end
