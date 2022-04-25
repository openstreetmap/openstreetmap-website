json.type "FeatureCollection"

json.features(@notes) do |note|
  json.partial! note
end
