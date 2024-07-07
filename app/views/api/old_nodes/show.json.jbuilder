json.partial! "api/root_attributes"

json.elements do
  json.array! [@old_element], :partial => "old_node", :as => :old_node
end
