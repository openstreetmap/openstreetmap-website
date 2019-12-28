json.partial! "api/map/root_attributes"

json.elements(@elems) do |old_relation|
  json.partial! old_relation
end
