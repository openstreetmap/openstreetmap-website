json.partial! "api/root_attributes"

json.elements do
  json.array! @nodes, :partial => "node", :as => :node
end
