require "cgi"

module BrowseHelper
  def printable_name(object, version = false)
    id = if object.id.is_a?(Array)
           object.id[0]
         else
           object.id
         end
    name = t "printable_name.with_id", :id => id.to_s
    name = t "printable_name.with_version", :id => name, :version => object.version.to_s if version

    # don't look at object tags if redacted, so as to avoid giving
    # away redacted version tag information.
    unless object.redacted?
      locale = I18n.locale.to_s

      locale = locale.sub(/-[^-]+/, "") while locale =~ /-[^-]+/ && !object.tags.include?("name:#{I18n.locale}")

      if object.tags.include? "name:#{locale}"
        name = t "printable_name.with_name_html", :name => content_tag(:bdi, object.tags["name:#{locale}"].to_s), :id => content_tag(:bdi, name)
      elsif object.tags.include? "name"
        name = t "printable_name.with_name_html", :name => content_tag(:bdi, object.tags["name"].to_s), :id => content_tag(:bdi, name)
      elsif object.tags.include? "ref"
        name = t "printable_name.with_name_html", :name => content_tag(:bdi, object.tags["ref"].to_s), :id => content_tag(:bdi, name)
      end
    end

    name
  end

  def link_class(type, object)
    classes = [type]

    if object.redacted?
      classes << "deleted"
    else
      classes += icon_tags(object).flatten.map { |t| h(t) }
      classes << "deleted" unless object.visible?
    end

    classes.join(" ")
  end

  def link_title(object)
    if object.redacted?
      ""
    else
      h(icon_tags(object).map { |k, v| k + "=" + v }.to_sentence)
    end
  end

  def link_follow(object)
    "nofollow" if object.tags.empty?
  end

  def type_and_paginated_count(type, pages)
    if pages.page_count == 1
      t "browse.changeset.#{type}",
        :count => pages.item_count
    else
      t "browse.changeset.#{type}_paginated",
        :x => pages.current_page.first_item,
        :y => pages.current_page.last_item,
        :count => pages.item_count
    end
  end

  private

  ICON_TAGS = %w[aeroway amenity barrier building highway historic landuse leisure man_made natural railway shop tourism waterway].freeze

  def icon_tags(object)
    object.tags.find_all { |k, _v| ICON_TAGS.include? k }.sort
  end
end
