# A map of each OSM key to its formatter URL. For example:
# { "ref:vatin" => "https://example.com/$1" }
# The JSON data is an array with duplicate entries, which is not efficient for lookups.
# So, convert it to a hash and only keep the item with the best rank.
TAG2LINK = JSON.parse(Rails.root.join("node_modules/tag2link/index.json").read)
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
