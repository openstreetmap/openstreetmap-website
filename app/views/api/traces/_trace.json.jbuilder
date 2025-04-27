# frozen_string_literal: true

json.id trace.id
json.name trace.name
json.uid trace.user_id
json.user trace.user.display_name
json.visibility trace.visibility
json.pending !trace.inserted
json.timestamp trace.timestamp.xmlschema

if trace.inserted
  json.lat trace.latitude
  json.lon trace.longitude
end

json.description trace.description
json.tags trace.tags.map(&:tag)
