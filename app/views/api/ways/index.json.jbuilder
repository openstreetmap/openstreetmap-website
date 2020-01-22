json.partial! "api/root_attributes"

json.elements(@ways) do |way|
  json.partial! way
end
