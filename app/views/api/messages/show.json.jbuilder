# frozen_string_literal: true

json.partial! "api/root_attributes"

json.message do
  json.partial! @message
end
