# frozen_string_literal: true

json.partial! "api/root_attributes"

json.changeset do
  json.partial! @changeset
end
