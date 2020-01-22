json.partial! "api/root_attributes"

all = @nodes + [@way]

json.elements(all) do |obj|
  json.partial! obj
end
