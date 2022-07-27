attrs = {
  "id" => old_relation.relation_id,
  "visible" => old_relation.visible,
  "version" => old_relation.version,
  "changeset" => old_relation.changeset_id,
  "timestamp" => old_relation.timestamp.xmlschema,
  "user" => old_relation.changeset.user.display_name,
  "uid" => old_relation.changeset.user_id
}

xml.relation(attrs) do |r|
  old_relation.relation_members.each do |m|
    r.member(:type => m.member_type.downcase, :ref => m.member_id, :role => m.member_role)
  end

  old_relation.tags.each do |k, v|
    r.tag(:k => k, :v => v)
  end
end
