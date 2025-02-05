json.partial! "api/root_attributes"

json.elements do
  json.array! @elems, :partial => "old_way", :as => :old_way
end
