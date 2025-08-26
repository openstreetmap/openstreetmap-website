json.partial! "api/root_attributes"

json.elements do
  json.array! @elements, :partial => "old_node", :as => :old_node
end
