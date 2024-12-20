json.partial! "api/root_attributes"

json.elements do
  json.array! @nodes, :partial => "/api/nodes/node", :as => :node
  json.array! [@way], :partial => "/api/ways/way", :as => :way
end
