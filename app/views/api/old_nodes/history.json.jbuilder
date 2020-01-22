json.partial! "api/root_attributes"

json.elements(@elems) do |old_node|
  json.partial! old_node
end
