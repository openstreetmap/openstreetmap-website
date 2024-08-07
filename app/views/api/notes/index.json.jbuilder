json.type "FeatureCollection"

json.features do
  json.array! @notes, :partial => "note", :as => :note
end
