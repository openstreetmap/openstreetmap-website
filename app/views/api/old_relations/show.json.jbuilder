json.partial! "api/root_attributes"

json.elements do
  json.array! [@old_element], :partial => "old_relation", :as => :old_relation
end
