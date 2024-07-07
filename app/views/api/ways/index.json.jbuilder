json.partial! "api/root_attributes"

json.elements do
  json.array! @ways, :partial => "way", :as => :way
end
