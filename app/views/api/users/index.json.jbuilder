json.partial! "api/root_attributes"

json.users(@users) do |user|
  json.partial! user
end
