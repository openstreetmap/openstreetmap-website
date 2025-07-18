TAG2LINK_RANKS = %w[deprecated normal preferred].freeze

# A map of each OSM key to its formatter URL. For example:
# { "ref:vatin" => "https://example.com/$1" }
# The JSON data is an array with duplicate entries, which is not efficient for lookups.
# So, convert it to a hash and only keep the item with the best rank.
TAG2LINK = JSON.parse(Rails.root.join("node_modules/tag2link/index.json").read)
               .reject { |item| item["rank"] == "deprecated" }
               .group_by { |item| item["key"] }
               .transform_keys { |key| key.sub(/^Key:/, "") }
               .transform_values { |items| items.max_by { |item| TAG2LINK_RANKS.index(item["rank"]) }.fetch("url") }
