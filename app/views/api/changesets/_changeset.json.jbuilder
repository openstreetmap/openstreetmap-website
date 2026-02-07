# frozen_string_literal: true

# basic attributes
json.id changeset.id
json.created_at changeset.created_at.xmlschema
json.open changeset.open?
json.comments_count changeset.comments.length
json.changes_count changeset.num_changes
json.num_created_nodes changeset.num_created_nodes
json.num_modified_nodes changeset.num_modified_nodes
json.num_deleted_nodes changeset.num_deleted_nodes
json.num_created_ways changeset.num_created_ways
json.num_modified_ways changeset.num_modified_ways
json.num_deleted_ways changeset.num_deleted_ways
json.num_created_relations changeset.num_created_relations
json.num_modified_relations changeset.num_modified_relations
json.num_deleted_relations changeset.num_deleted_relations

json.closed_at changeset.closed_at.xmlschema unless changeset.open?
if changeset.bbox.complete?
  json.min_lat GeoRecord::Coord.new(changeset.bbox.to_unscaled.min_lat)
  json.min_lon GeoRecord::Coord.new(changeset.bbox.to_unscaled.min_lon)
  json.max_lat GeoRecord::Coord.new(changeset.bbox.to_unscaled.max_lat)
  json.max_lon GeoRecord::Coord.new(changeset.bbox.to_unscaled.max_lon)
end

# user attributes
if changeset.user.data_public?
  json.uid changeset.user_id
  json.user changeset.user.display_name
end

json.tags changeset.tags unless changeset.tags.empty?

if @comments
  json.comments(@comments) do |comment|
    json.partial! comment
  end
end
