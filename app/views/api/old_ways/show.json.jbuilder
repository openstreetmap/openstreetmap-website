json.partial! "api/root_attributes"

json.elements do
  json.array! [@old_element], :partial => "old_way", :as => :old_way
end
