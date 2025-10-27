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
      .group_by { |item| item["key"] }
      .transform_keys { |key| key.sub(/^Key:/, "") }
      # move preferred to the start of the array
      .transform_values { |items| items.sort_by { |item| item["rank"] == "preferred" ? 0 : 1 }.uniq { |item| item["url"] } }
      # exclude any that are ambiguous, i.e. the best and second-best have the same rank
      .reject { |_key, value| value[1] && value[0]["rank"] == value[1]["rank"] }
      # keep only the best match
      .transform_values { |items| items[0]["url"] }
  end
end
