json.partial! "api/map/root_attributes"

json.elements(@relations) do |relation|
  json.partial! relation
end
