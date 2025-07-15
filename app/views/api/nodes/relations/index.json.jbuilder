json.partial! "api/root_attributes"

json.elements do
  json.array! @relations, :partial => "api/relations/relation", :as => :relation
end
