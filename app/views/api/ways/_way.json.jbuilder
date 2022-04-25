json.type "way"
json.id way.id
json.timestamp way.timestamp.xmlschema
json.version way.version
json.changeset way.changeset_id
json.user way.changeset.user.display_name
json.uid way.changeset.user_id

json.visible way.visible unless way.visible

json.nodes way.nodes.ids unless way.nodes.ids.empty?

json.tags way.tags unless way.tags.empty?
