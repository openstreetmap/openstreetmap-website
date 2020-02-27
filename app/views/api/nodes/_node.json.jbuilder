json.type "node"
json.id node.id
if node.visible
  json.lat GeoRecord::Coord.new(node.lat)
  json.lon GeoRecord::Coord.new(node.lon)
end
json.timestamp node.timestamp.xmlschema
json.version node.version
json.changeset node.changeset_id
json.user node.changeset.user.display_name
json.uid node.changeset.user_id

json.visible node.visible unless node.visible

json.tags node.tags unless node.tags.empty?
