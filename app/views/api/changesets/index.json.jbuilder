json.partial! "api/root_attributes"

json.changesets do
  json.array! @changesets, :partial => "changeset", :as => :changeset
end
