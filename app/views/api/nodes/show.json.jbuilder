json.partial! "api/root_attributes"

json.elements do
  json.array! [@node], :partial => "node", :as => :node
end
