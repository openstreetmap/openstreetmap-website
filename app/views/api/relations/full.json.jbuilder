json.partial! "api/root_attributes"

json.elements do
  json.array! @nodes, :partial => "/api/nodes/node", :as => :node
  json.array! @ways, :partial => "/api/ways/way", :as => :way
  json.array! @relations, :partial => "/api/relations/relation", :as => :relation
end
