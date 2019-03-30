# basic attributes

attrs = {
  "id" => changeset.id,
  "created_at" => changeset.created_at.xmlschema,
  "open" => changeset.is_open?,
  "comments_count" => changeset.comments.length,
  "changes_count" => changeset.num_changes
}
attrs["closed_at"] = changeset.closed_at.xmlschema unless changeset.is_open?
changeset.bbox.to_unscaled.add_bounds_to(attrs, "_") if changeset.bbox.complete?

# user attributes

if changeset.user.data_public?
  attrs["uid"] = changeset.user_id
  attrs["user"] = changeset.user.display_name
end

xml.changeset(attrs) do |changeset_xml_node|
  changeset.tags.each do |k, v|
    changeset_xml_node.tag(:k => k, :v => v)
  end

  # include discussion if requested

  if @include_discussion
    changeset_xml_node.discussion do |discussion_xml_node|
      changeset.comments.includes(:author).each do |comment|
        cattrs = {
          "date" => comment.created_at.xmlschema
        }
        if comment.author.data_public?
          cattrs["uid"] = comment.author.id
          cattrs["user"] = comment.author.display_name
        end
        discussion_xml_node.comment(cattrs) do |comment_xml_node|
          comment_xml_node.text(comment.body)
        end
      end
    end
  end
end
