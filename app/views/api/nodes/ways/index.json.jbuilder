json.partial! "api/root_attributes"

json.elements do
  json.array! @ways, :partial => "api/ways/way", :as => :way
end
