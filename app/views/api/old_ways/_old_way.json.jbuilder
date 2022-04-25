json.type "way"
json.id old_way.way_id
json.timestamp old_way.timestamp.xmlschema
json.version old_way.version
json.changeset old_way.changeset_id
json.user old_way.changeset.user.display_name
json.uid old_way.changeset.user_id

json.visible old_way.visible unless old_way.visible

json.nodes old_way.nds unless old_way.nds.empty?

json.tags old_way.tags unless old_way.tags.empty?
