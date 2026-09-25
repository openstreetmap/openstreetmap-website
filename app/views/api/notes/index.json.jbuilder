# frozen_string_literal: true

json.type "FeatureCollection"

json.features do
  json.array! @notes, :partial => "note", :as => :note
end
