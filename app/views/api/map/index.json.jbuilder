json.partial! "root_attributes"

json.partial! "bounds"

all = @nodes + @ways + @relations

json.elements(all) do |object|
  case object
  when Relation, Node, Way
    json.id object.id
    json.timestamp object.timestamp.xmlschema
    json.version object.version
    json.changeset object.changeset_id
    json.user object.changeset.user.display_name
    json.uid object.changeset.user_id
    json.tags object.tags unless object.tags.empty?
    json.visible object.visible unless object.visible

    case object
    when Relation
      relation = object
      json.type "relation"
      unless relation.relation_members.empty?
        json.members(relation.relation_members) do |m|
          json.type m.member_type.downcase
          json.ref m.member_id
          json.role m.member_role
        end
      end
    when Node
      node = object
      json.type "node"
      if node.visible
        json.lat GeoRecord::Coord.new(node.lat)
        json.lon GeoRecord::Coord.new(node.lon)
      end
    when Way
      way = object
      json.type "way"
      json.nodes way.nodes.ids unless way.nodes.ids.empty?
    end
  else
    json.partial! object
  end
end
