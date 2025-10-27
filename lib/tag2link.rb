# frozen_string_literal: true

module Tag2link
  def self.load(path)
    @dict = build_dict(JSON.parse(path.read)).freeze
  end

  def self.link(key, value)
    # skip if it's a full URL
    return nil if %r{\Ahttps?://}.match?(value)

    url_template = @dict[key]
    return nil unless url_template

    url_template.gsub("$1", value)
  end

  def self.build_dict(data)
    data
      # exclude deprecated and third-party URLs
      .reject { |item| item["rank"] == "deprecated" || item["source"] == "wikidata:P3303" }
      .group_by { |item| item["key"].sub(/^Key:/, "") }
      .transform_values { |items| choose_best_item(items) }
      .compact
      .transform_values { |items| items["url"] }
  end

  def self.choose_best_item(items)
    return nil if items.blank?

    return items.first if items.size == 1

    # move preferred to the start of the array
    ranked = items.sort_by { |item| item["rank"] == "preferred" ? 0 : 1 }.uniq { |item| item["url"] }
    top_rank = ranked.first["rank"]
    top_items = ranked.select { |i| i["rank"] == top_rank }

    # if only one top-ranked item, prefer that
    return top_items.first if top_items.size == 1

    grouped = top_items.group_by { |i| i["source"] }
    return nil if grouped.size > 2

    # if both sources have exactly one preferred, prefer osmwiki
    return grouped["osmwiki:P8"]&.first || grouped.values.flatten.first if grouped.all? { |_s, vals| vals.size == 1 }

    # if one source has multiple preferreds and the other has one, prefer the single one
    return grouped.min_by { |_s, vals| vals.size }.last.first if grouped.any? { |_s, vals| vals.size == 1 }

    # exclude any that are ambiguous
    nil
  end
  private_class_method :choose_best_item
end
