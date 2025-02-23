json.partial! "api/root_attributes"

json.changeset do
  json.partial! "api/changesets/changeset", :changeset => @changeset
end
