json.partial! "api/map/root_attributes"

all = @nodes + [@way]

json.elements(all) do |obj|
  json.partial! obj
end
