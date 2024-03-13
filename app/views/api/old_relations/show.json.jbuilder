json.partial! "api/root_attributes"

json.elements([@old_element]) do |old_relation|
  json.partial! old_relation
end
