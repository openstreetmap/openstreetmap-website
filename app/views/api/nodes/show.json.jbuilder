json.partial! "api/map/root_attributes"

json.elements([@node]) do |node|
  json.partial! node
end
