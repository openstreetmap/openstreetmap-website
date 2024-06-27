json.partial! "api/root_attributes"

json.elements do
  json.array! @elems, :partial => "old_node", :as => :old_node
end
