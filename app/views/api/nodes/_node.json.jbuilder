json.type "node"
json.id node.id
if node.visible
  json.lat format("%.7f", node.lat.to_f)
  json.lon format("%.7f", node.lon.to_f)
end
json.timestamp node.timestamp.xmlschema
json.version node.version
json.changeset node.changeset_id
json.user node.changeset.user.display_name
json.uid node.changeset.user_id

json.visible node.visible unless node.visible

json.tags node.tags unless node.tags.empty?
