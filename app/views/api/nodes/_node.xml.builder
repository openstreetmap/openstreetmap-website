attrs = {
  "id" => node.id,
  "visible" => node.visible,
  "version" => node.version,
  "changeset" => node.changeset_id,
  "timestamp" => node.timestamp.xmlschema,
  "user" => node.changeset.user.display_name,
  "uid" => node.changeset.user_id
}

if node.visible
  attrs["lat"] = node.lat
  attrs["lon"] = node.lon
end

if node.tags.empty?
  xml.node(attrs)
else
  xml.node(attrs) do |nd|
    node.tags.each do |k, v|
      nd.tag(:k => k, :v => v)
    end
  end
end
