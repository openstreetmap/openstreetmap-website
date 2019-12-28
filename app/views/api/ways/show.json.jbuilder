json.partial! "api/map/root_attributes"

json.elements([@way]) do |way|
  json.partial! way
end
