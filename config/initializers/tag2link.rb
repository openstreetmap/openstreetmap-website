# A map of each OSM key to its formatter URL. For example:
# { "ref:vatin" => "https://example.com/$1" }
TAG2LINK = lambda {
  # the JSON data is an array with duplicate entries, which is not efficient for lookups.
  # So, convert it to a hash and only keep the item with the best rank.
  array = JSON.parse(Rails.root.join("node_modules/tag2link/index.json").read)

  ranks = %w[deprecated normal preferred].freeze

  output = {}

  all_keys = array.map { |item| item["key"] }.uniq

  all_keys.each do |key|
    # for each key, find the item with the best rank
    best_definition = array
                      .select { |item| item["key"] == key }
                      .reject { |item| item["rank"] == "deprecated" }
                      .max_by { |item| ranks.index(item["rank"]) }

    output[key.sub(/^Key:/, "")] = best_definition["url"]
  end

  output
}.call
