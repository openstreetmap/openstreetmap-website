json.partial! "root_attributes"

json.partial! "bounds"

all = @nodes + @ways + @relations

json.elements(all) do |obj|
  json.partial! obj
end
