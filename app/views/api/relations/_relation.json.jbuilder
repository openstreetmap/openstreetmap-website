json.type "relation"
json.id relation.id
json.timestamp relation.timestamp.xmlschema
json.version relation.version
json.changeset relation.changeset_id
json.user relation.changeset.user.display_name
json.uid relation.changeset.user_id

json.visible relation.visible unless relation.visible

unless relation.relation_members.empty?
  json.members(relation.relation_members) do |m|
    json.type m.member_type.downcase
    json.ref m.member_id
    json.role m.member_role
  end
end

json.tags relation.tags unless relation.tags.empty?
