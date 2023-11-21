json.partial! "api/root_attributes"

json.comments(@comments) do |comment|
  json.partial! comment
end
