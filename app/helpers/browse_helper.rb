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

  # Tag change highlighting methods for history view
  def tag_changes_for_version(current_version, all_versions)
    return {} unless current_version && all_versions

    current_tags = current_version.tags || {}

    # Find the previous version by sorting all versions and finding the one before current
    sorted_versions = all_versions.sort_by(&:version)
    current_index = sorted_versions.find_index { |v| v.version == current_version.version }
    previous_version = current_index && current_index > 0 ? sorted_versions[current_index - 1] : nil
    previous_tags = previous_version&.tags || {}

    # Check for added and modified tags
    changes = current_tags.each_with_object({}) do |(key, value), memo|
      if !previous_tags.key?(key)
        memo[key] = { type: :added, current: value }
      elsif previous_tags[key] != value
        memo[key] = { type: :modified, current: value, previous: previous_tags[key] }
      else
        memo[key] = { type: :unchanged, current: value }
      end
    end

    # Check for deleted tags
    previous_tags.keys.difference(current_tags.keys).each do |key|
      changes[key] = { type: :deleted }
    end

    changes
  end

  def tag_change_class(change_type)
    case change_type
    when :added
      "tag-added"
    when :modified
      "tag-modified"
    when :deleted
      "tag-deleted"
    else
      "tag-unmodified"
    end
  end

  def format_tag_value_with_change(key, change_info)
    case change_info[:type]
    when :added
      format_value(key, change_info[:current])
    when :modified
      "#{format_value(key, change_info[:previous])} → #{format_value(key, change_info[:current])}".html_safe
    when :deleted
      tag.em("deleted")
    else
      format_value(key, change_info[:current])
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
