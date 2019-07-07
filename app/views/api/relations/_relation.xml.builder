attrs = {
  "id" => relation.id,
  "visible" => relation.visible,
  "version" => relation.version,
  "changeset" => relation.changeset_id,
  "timestamp" => relation.timestamp.xmlschema,
  "user" => relation.changeset.user.display_name,
  "uid" => relation.changeset.user_id
}

xml.relation(attrs) do |r|
  relation.relation_members.each do |m|
    r.member(:type => m.member_type.downcase, :ref => m.member_id, :role => m.member_role)
  end

  relation.tags.each do |k, v|
    r.tag(:k => k, :v => v)
  end
end
