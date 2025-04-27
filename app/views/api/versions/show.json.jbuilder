# frozen_string_literal: true

json.partial! "api/root_attributes"

json.api do
  json.versions @versions
end
