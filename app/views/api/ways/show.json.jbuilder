json.partial! "api/root_attributes"

json.elements do
  json.array! @nodes, :partial => "/api/nodes/node", :as => :node if @nodes
  json.array! [@way], :partial => "way", :as => :way
end
