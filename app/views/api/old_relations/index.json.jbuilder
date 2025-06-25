json.partial! "api/root_attributes"

json.elements do
  json.array! @elems, :partial => "old_relation", :as => :old_relation
end
