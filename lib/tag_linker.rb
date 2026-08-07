# frozen_string_literal: true

module TagLinker
  def self.init(paths)
    @tag2link_dict = build_tag2link_dict(JSON.parse(paths[:tag2link].read)).freeze
    @wiki_pages_dict = YAML.load_file(paths[:wiki_pages]).freeze
  end

  def self.wiki_link(type, title)
    locale = I18n.locale.to_s

    # update-wiki-pages does s/ /_/g on keys before saving them, we
    # have to replace spaces with underscore so we'll link
    # e.g. `source=Isle of Man Government aerial imagery (2001)' to
    # the correct page.
    lookup = title.tr(" ", "_")

    page = @wiki_pages_dict.dig(locale, type, lookup) ||
           @wiki_pages_dict.dig("en", type, lookup)

    url = "https://wiki.openstreetmap.org/wiki/#{page}?uselang=#{locale}" if page

    url
  end

  def self.tag2link_link(key, value)
    # skip if it's a full URL
    return nil if %r{\Ahttps?://}.match?(value)

    url_template = @tag2link_dict[key]
    return nil unless url_template

    url_template.gsub("$1", value.sub(/^#/, ""))
  end

  def self.build_tag2link_dict(data)
    data
      # exclude deprecated, third-party, and non-HTTP URLs
      .reject { |item| item["rank"] == "deprecated" || item["source"] == "wikidata:P3303" || !item["url"].match?(%r{\Ahttps?://[^$]}) }
      .group_by { |item| item["key"].sub(/^Key:/, "") }
      .transform_values { |items| choose_best_tag2link_item(items) }
      .compact
      .transform_values { |items| items["url"] }
  end

  def self.choose_best_tag2link_item(items)
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
  private_class_method :choose_best_tag2link_item
end
