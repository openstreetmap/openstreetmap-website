json.partial! "api/root_attributes"

json.changesets(@changesets) do |changeset|
  json.partial! changeset
end
