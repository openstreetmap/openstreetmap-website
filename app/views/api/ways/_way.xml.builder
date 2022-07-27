attrs = {
  "id" => way.id,
  "visible" => way.visible,
  "version" => way.version,
  "changeset" => way.changeset_id,
  "timestamp" => way.timestamp.xmlschema,
  "user" => way.changeset.user.display_name,
  "uid" => way.changeset.user_id
}

xml.way(attrs) do |w|
  way.nodes.each do |n|
    w.nd(:ref => n.id)
  end

  way.tags.each do |k, v|
    w.tag(:k => k, :v => v)
  end
end
