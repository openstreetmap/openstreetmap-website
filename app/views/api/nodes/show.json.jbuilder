json.partial! "api/root_attributes"

json.elements([@node]) do |node|
  json.partial! node
end
