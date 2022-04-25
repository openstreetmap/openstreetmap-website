json.type "relation"
json.id old_relation.relation_id
json.timestamp old_relation.timestamp.xmlschema
json.version old_relation.version
json.changeset old_relation.changeset_id
json.user old_relation.changeset.user.display_name
json.uid old_relation.changeset.user_id

json.visible old_relation.visible unless old_relation.visible

unless old_relation.relation_members.empty?
  json.members(old_relation.relation_members) do |m|
    json.type m.member_type.downcase
    json.ref m.member_id
    json.role m.member_role
  end
end

json.tags old_relation.tags unless old_relation.tags.empty?
