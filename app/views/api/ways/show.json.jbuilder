json.partial! "api/root_attributes"

json.elements do
  json.array! [@way], :partial => "way", :as => :way
end
