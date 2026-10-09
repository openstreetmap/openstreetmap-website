# frozen_string_literal: true

json.partial! "api/root_attributes"

json.last_id @last_id

json.changes @events do |event|
  json.id event.id
  json.gpx_id event.gpx_id
  json.action event.action
  json.timestamp event.created_at.xmlschema
end
