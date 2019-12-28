json.partial! "api/map/root_attributes"

json.elements(@nodes) do |node|
  json.partial! node
end
