json.partial! "api/root_attributes"

json.elements([@old_element]) do |old_node|
  json.partial! old_node
end
