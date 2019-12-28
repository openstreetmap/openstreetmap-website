json.type "node"
json.id old_node.node_id
if old_node.visible
  json.lat format("%.7f", old_node.lat.to_f)
  json.lon format("%.7f", old_node.lon.to_f)
end
json.timestamp old_node.timestamp.xmlschema
json.version old_node.version
json.changeset old_node.changeset_id
json.user old_node.changeset.user.display_name
json.uid old_node.changeset.user_id

json.visible old_node.visible unless old_node.visible

json.tags old_node.tags unless old_node.tags.empty?
