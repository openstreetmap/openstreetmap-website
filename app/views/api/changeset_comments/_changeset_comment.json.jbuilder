json.id changeset_comment.id
json.visible changeset_comment.visible
json.date changeset_comment.created_at.xmlschema
if changeset_comment.author.data_public?
  json.uid changeset_comment.author.id
  json.user changeset_comment.author.display_name
end
json.text changeset_comment.body
