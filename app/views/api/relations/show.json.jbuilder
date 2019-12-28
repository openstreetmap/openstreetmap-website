json.partial! "api/map/root_attributes"

json.elements([@relation]) do |relation|
  json.partial! relation
end
