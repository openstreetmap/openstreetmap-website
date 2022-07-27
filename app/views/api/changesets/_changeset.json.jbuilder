# basic attributes
json.id changeset.id
json.created_at changeset.created_at.xmlschema
json.open changeset.open?
json.comments_count changeset.comments.length
json.changes_count changeset.num_changes

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

if @include_discussion
  json.comments(changeset.comments) do |comment|
    json.date comment.created_at.xmlschema
    if comment.author.data_public?
      json.uid comment.author.id
      json.user comment.author.display_name
    end
    json.text comment.body
  end
end
