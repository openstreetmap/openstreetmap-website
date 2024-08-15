module BrowseHelper
  def element_single_current_link(type, object)
    block = -> { printable_element_name object }
    svg_icon = lookup_svg_icon(object)
    if svg_icon
      link_to object, { :class => type, :title => element_title(object), :rel => (link_follow(object) if type == "node") } do
        concat external_svg(svg_icon)
        concat element_strikethrough object, &block
      end
    else
      link_to object, { :class => element_class(type, object), :title => element_title(object), :rel => (link_follow(object) if type == "node") } do
        element_strikethrough object, &block
      end
    end
  end

  def element_list_item(type, object, &block)
    svg_icon = lookup_svg_icon(object)
    if svg_icon
      tag.li :class => type, :title => element_title(object) do
        concat external_svg(svg_icon)
        concat element_strikethrough object, &block
      end
    else
      tag.li :class => element_class(type, object), :title => element_title(object) do
        element_strikethrough object, &block
      end
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

  def element_class(type, object)
    classes = [type]
    classes += icon_tags(object).flatten.map { |t| h(t) } unless object.redacted?
    classes.join(" ")
  end

  def element_title(object)
    if object.redacted?
      ""
    else
      h(icon_tags(object).map { |k, v| "#{k}=#{v}" }.to_sentence)
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

  ICON_TAGS = %w[advertising aeroway amenity barrier building emergency highway historic landuse leisure man_made natural office railway shop tourism waterway].freeze

  def icon_tags(object)
    object.tags.find_all { |k, _v| ICON_TAGS.include? k }.sort
  end

  def name_locales(object)
    object.tags.keys.map { |k| Regexp.last_match(1) if k =~ /^name:(.*)$/ }.flatten
  end

  def external_svg(args, attributes = {})
    file_name, fragment = args[:image].split("#")
    fragment ||= "icon"
    attributes[:xmlns] = "http://www.w3.org/2000/svg"
    attributes[:class] = args[:css_class].compact_blank.join(" ")
    file_name = "browse/#{file_name}"
    content_tag :svg, attributes do
      tag.use :href => "#{image_path(file_name)}##{fragment}"
    end
  end

  def lookup_svg_icon(object)
    return if object.redacted?

    icon_tags = icon_tags(object)

    # lookup key-value
    elem_icon_kv = icon_tags.map { |k, v| "#{k}_#{v}" }.last
    icon = BROWSE_IMAGE[elem_icon_kv.to_sym] if elem_icon_kv

    # fallback: lookup key only (eg. shop)
    unless icon
      elem_icon_k = icon_tags.map { |k, _| k }.last
      icon = BROWSE_IMAGE[elem_icon_k.to_sym] if elem_icon_k
    end

    if icon
      { :image => icon[:image],
        :css_class => [icon[:fill], "svg_icon"] }
    end
  end
end
