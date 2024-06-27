json.partial! "api/root_attributes"

json.elements do
  json.array! [@relation], :partial => "relation", :as => :relation
end
