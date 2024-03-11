json.partial! "api/root_attributes"

json.messages(@messages) do |message|
  json.partial! message
end
