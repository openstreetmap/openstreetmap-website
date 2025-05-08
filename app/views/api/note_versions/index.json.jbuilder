json.type "FeatureCollection"

json.features do
  json.array! @note_versions, :partial => "note_version", :as => :note_version
end
