attrs = {
  "id" => old_node.node_id,
  "visible" => old_node.visible,
  "version" => old_node.version,
  "changeset" => old_node.changeset_id,
  "timestamp" => old_node.timestamp.xmlschema,
  "user" => old_node.changeset.user.display_name,
  "uid" => old_node.changeset.user_id
}

if old_node.visible
  attrs["lat"] = old_node.lat
  attrs["lon"] = old_node.lon
end

if old_node.tags.empty?
  xml.node(attrs)
else
  xml.node(attrs) do |nd|
    old_node.tags.each do |k, v|
      nd.tag(:k => k, :v => v)
    end
  end
end
