json.partial! "api/map/root_attributes"

all = @nodes + @ways + @relations

json.elements(all) do |obj|
  json.partial! obj
end
