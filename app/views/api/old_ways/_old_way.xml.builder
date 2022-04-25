attrs = {
  "id" => old_way.way_id,
  "visible" => old_way.visible,
  "version" => old_way.version,
  "changeset" => old_way.changeset_id,
  "timestamp" => old_way.timestamp.xmlschema,
  "user" => old_way.changeset.user.display_name,
  "uid" => old_way.changeset.user_id
}

xml.way(attrs) do |w|
  old_way.nds.each do |n|
    w.nd(:ref => n)
  end

  old_way.tags.each do |k, v|
    w.tag(:k => k, :v => v)
  end
end
