module BrowseHelper
  def element_single_current_link(type, object)
    link_to object, { :class => element_class(type, object), :title => element_title(object), :rel => (link_follow(object) if type == "node") } do
      element_strikethrough object do
        printable_element_name object
      end
    end
  end

  def element_list_item(type, object, &block)
    tag.li :class => element_class(type, object), :title => element_title(object) do
      element_strikethrough object, &block
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

  def type_and_paginated_count(type, paginator, page = paginator.current_page)
    if paginator.pages_count <= 1
      t ".#{type.pluralize}",
        :count => paginator.elements_count
    else
      t ".#{type.pluralize}_paginated",
        :x => paginator.lower_element_number(page),
        :y => paginator.upper_element_number(page),
        :count => paginator.elements_count
    end
  end

  def sidebar_classic_pagination(paginator, page_param)
    window_size = 2
    max_width_for_default_padding = 35

    pages = paginator.pages
    window = paginator.pages_window(window_size)
    page_items = []

    if window.first != pages.first
      page_items.push [pages.first.to_s, pages.first]
      page_items.push ["...", "disabled"] if window.first - pages.first > 1
    end

    window.each do |page|
      if paginator.current_page == page
        page_items.push [page.to_s, "active"]
      else
        page_items.push [page.to_s, page]
      end
    end

    if window.last != pages.last
      page_items.push ["...", "disabled"] if pages.last - window.last > 1
      page_items.push [pages.last.to_s, pages.last]
    end

    width = 0
    page_items.each do |(body)|
      width += 2 # padding width
      width += body.length
    end
    link_classes = ["page-link", { "px-1" => width > max_width_for_default_padding }]

    tag.ul :class => "pagination pagination-sm mb-2" do
      page_items.each do |body, page_or_class|
        linked = !(page_or_class.is_a? String)
        link = if linked
                 link_to body, url_for(page_param => page_or_class), :class => link_classes, **yield(page_or_class)
               else
                 tag.span body, :class => link_classes
               end
        concat tag.li link, :class => ["page-item", { page_or_class => !linked }]
      end
    end
  end

  private

  ICON_TAGS = %w[aeroway amenity barrier building highway historic landuse leisure man_made natural office railway shop tourism waterway].freeze

  def icon_tags(object)
    object.tags.find_all { |k, _v| ICON_TAGS.include? k }.sort
  end

  def name_locales(object)
    object.tags.keys.map { |k| Regexp.last_match(1) if k =~ /^name:(.*)$/ }.flatten
  end
end
