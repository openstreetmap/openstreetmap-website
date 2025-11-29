# frozen_string_literal: true

module BrowseTagChangesHelper
  include BrowseTagsHelper

  def wrap_tags_with_version_changes(tags_to_values, current_version = nil, all_versions = [])
    # Find the previous usable version by looking backwards through all versions
    previous_version = all_versions
                       .find_index { |v| v.version == current_version }
                       &.then { |index| index.positive? ? all_versions[0...index].reverse : nil }
                       &.find { |v| !v.redacted? || params[:show_redactions] }

    previous_tags = previous_version&.tags || {}

    tags_added = tags_modified = tags_unmodified = tags_removed = tags_with_unknown_versioning = {}

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

      tags_removed = previous_tags.keys.difference(tags_to_values.keys).index_with do |key|
        { :type => :removed, :previous => previous_tags[key] }
      end
    else
      tags_with_unknown_versioning = tags_to_values.transform_values do |value|
        { :current => value }
      end
    end

    tags_with_unknown_versioning.merge(tags_added, tags_modified, tags_unmodified, tags_removed)
  end

  def tag_change_class(change_type)
    {
      :added => "tag-added",
      :modified => "tag-modified",
      :removed => "tag-removed",
      :unmodified => "tag-unmodified"
    }.fetch(change_type, "")
  end

  def format_tag_value_with_change(key, change_info)
    case change_info[:type]
    when :added
      tag.ins(format_value(key, change_info[:current], :skip_wikidata_preview => true))
    when :unmodified
      # For added and unmodified show the current value without the wikidata preview
      format_value(key, change_info[:current], :skip_wikidata_preview => true)
    when :modified
      # Return array of two values for the two rows that will be created
      [
        tag.del(format_value(key, change_info[:previous], :skip_wikidata_preview => true)),
        tag.ins(format_value(key, change_info[:current], :skip_wikidata_preview => true))
      ]
    when :removed
      tag.del(format_value(key, change_info[:previous] || "", :skip_wikidata_preview => true))
    when nil
      # For unknown versioning show the current value with the wikidata preview
      format_value(key, change_info[:current] || "", :skip_wikidata_preview => false)
    end
  end

  def get_change_indicator_text(change_type)
    case change_type
    when :added
      "+"
    when :removed
      "−"
    else
      " "
    end
  end

  def get_indicator_cell_class(change_type)
    case change_type
    when :added
      "diff-indicator-cell diff-added"
    when :removed
      "diff-indicator-cell diff-removed"
    when :unmodified
      "diff-indicator-cell diff-unmodified"
    else
      "diff-indicator-cell"
    end
  end

  def format_tag_row_with_change(key, change_info)
    case change_info[:type]
    when :modified
      # Generate two rows for modified tags, using tag-removed and tag-added classes on rows
      value_cells = format_tag_value_with_change(key, change_info)
      [
        tag.tr(:class => "tag-removed") do
          safe_join([
                      tag.th(format_key(key), :class => "py-1 border-secondary-subtle table-secondary fw-normal diff-key-modified", :rowspan => 2),
                      tag.td(get_change_indicator_text(:removed), :class => get_indicator_cell_class(:removed)),
                      tag.td(value_cells[0], :class => "py-1 diff-cell")
                    ])
        end,
        tag.tr(:class => "tag-added") do
          safe_join([
                      tag.td(get_change_indicator_text(:added), :class => get_indicator_cell_class(:added)),
                      tag.td(value_cells[1], :class => "py-1 diff-cell")
                    ])
        end
      ]
    else
      # Generate single row for other change types
      cells = [tag.th(format_key(key), :class => "py-1 border-secondary-subtle table-secondary fw-normal")]

      # Only add diff indicator cell if we're in a history/diff context
      cells << tag.td(get_change_indicator_text(change_info[:type]), :class => get_indicator_cell_class(change_info[:type])) if change_info[:type]

      cells << tag.td(format_tag_value_with_change(key, change_info), :class => "py-1")

      [
        tag.tr(:class => tag_change_class(change_info[:type])) do
          safe_join(cells)
        end
      ]
    end
  end
end
