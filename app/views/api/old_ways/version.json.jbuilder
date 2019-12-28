json.partial! "api/map/root_attributes"

json.elements([@old_element]) do |old_way|
  json.partial! old_way
end
