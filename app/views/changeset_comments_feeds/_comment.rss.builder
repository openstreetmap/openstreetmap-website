xml.item do
  xml.title t(".comment", :author => comment.author.display_name, :changeset_id => comment.changeset.id.to_s)

  xml.link changeset_url(comment.changeset, :anchor => "c#{comment.id}")
  xml.guid changeset_url(comment.changeset, :anchor => "c#{comment.id}")

  xml.description do
    xml.cdata! render(:partial => "comment", :object => comment, :formats => [:html])
  end

  xml.dc :creator, comment.author.display_name if comment.author

  xml.pubDate comment.created_at.to_fs(:rfc822)
end
