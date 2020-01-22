json.partial! "api/root_attributes"

json.elements(@elems) do |old_way|
  json.partial! old_way
end
