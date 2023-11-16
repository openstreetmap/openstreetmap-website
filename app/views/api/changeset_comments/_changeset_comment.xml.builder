cattrs = {
  "id" => changeset_comment.id,
  "date" => changeset_comment.created_at.xmlschema,
  "visible" => changeset_comment.visible
}
if changeset_comment.author.data_public?
  cattrs["uid"] = changeset_comment.author.id
  cattrs["user"] = changeset_comment.author.display_name
end
xml.comment(cattrs) do |comment_xml_node|
  comment_xml_node.text(changeset_comment.body)
end
