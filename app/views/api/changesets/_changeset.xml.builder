# basic attributes

attrs = {
  "id" => changeset.id,
  "created_at" => changeset.created_at.xmlschema,
  "open" => changeset.open?,
  "comments_count" => changeset.comments.length,
  "changes_count" => changeset.num_changes
}
attrs["closed_at"] = changeset.closed_at.xmlschema unless changeset.open?
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

  if @comments
    changeset_xml_node.discussion do |discussion_xml_node|
      @comments.each do |comment|
        discussion_xml_node << render(comment)
      end
    end
  end
end
