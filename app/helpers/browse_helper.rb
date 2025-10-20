# frozen_string_literal: true

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

  def wrap_tags_with_version_changes(tags_to_values, current_version = nil, all_versions = [])
    # Find the previous usable version by looking backwards through all versions
    previous_version = all_versions
                       .find_index { |v| v.version == current_version }
                       &.then { |index| index.positive? ? all_versions[0...index].reverse : nil }
                       &.find { |v| !v.redacted? || params[:show_redactions] }

    previous_tags = previous_version&.tags || {}

    tags_added = tags_modified = tags_unmodified = tags_deleted = tags_with_unknown_versioning = {}

    if all_versions.present?
      tags_added = tags_to_values
                   .except(*previous_tags.keys)
                   .transform_values { |value| { :type => :added, :current => value } }

      tags_modified = tags_to_values
                      .filter { |name, value| previous_tags.key?(name) && previous_tags[name] != value }
                      .each_with_object({}) do |(name, value), memo|
        memo[name] = { :type => :modified, :current => value, :previous => previous_tags[name] }
      end

      tags_unmodified = tags_to_values
                        .filter { |name, value| previous_tags[name] == value }
                        .transform_values { |value| { :type => :unmodified, :current => value } }

      tags_deleted = previous_tags.keys.difference(tags_to_values.keys).index_with do |key|
        { :type => :deleted, :previous => previous_tags[key] }
      end
    else
      tags_with_unknown_versioning = tags_to_values.transform_values do |value|
        { :current => value }
      end
    end

    tags_with_unknown_versioning.merge(tags_added, tags_modified, tags_unmodified, tags_deleted)
  end

  def tag_change_class(change_type)
    {
      :added => "tag-added",
      :modified => "tag-modified",
      :deleted => "tag-deleted",
      :unmodified => "tag-unmodified"
    }.fetch(change_type, "")
  end

  def format_tag_value_with_change(key, change_info)
    case change_info[:type]
    when :added
      tag.div(safe_join(["+", format_value(key, change_info[:current])], " "), :class => "diff-new")
    when :unmodified
      tag.div(safe_join([tag.nbsp, format_value(key, change_info[:current])], " "), :class => "diff-unchanged")
    when :modified
      safe_join([
                  tag.div(safe_join(["-", format_value(key, change_info[:previous])], " "), :class => "diff-old"),
                  tag.div(safe_join(["+", format_value(key, change_info[:current])], " "), :class => "diff-new")
                ])
    when :deleted
      tag.div(safe_join(["-", format_value(key, change_info[:previous] || "")], " "), :class => "diff-old")
    else
      change_info[:current]
    end
  end

  private

  def feature_name(tags)
    return nil if tags.empty?

    locale_keys = preferred_languages.expand.map { |locale| "name:#{locale}" }

    (locale_keys + %w[name ref addr:housename]).each do |key|
      return tags[key] if tags[key]
    end
    return "#{tags['addr:housenumber']} #{tags['addr:street']}" if tags["addr:housenumber"] && tags["addr:street"]

    nil
  end
end
