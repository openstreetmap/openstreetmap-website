changeset_attributes = { :id => changeset.id, :created_at => changeset.created_at.xmlschema, :closed_at => changeset.closed_at, :open => changeset.is_open? }
changeset_attributes[:uid] = changeset.user.id if changeset.user.data_public?
changeset_attributes[:user] = changeset.user.display_name if changeset.user.data_public?
changeset.bbox.to_unscaled.add_bounds_to(changeset_attributes, '_') if changeset.bbox.complete?

xml.changeset(changeset_attributes) do |asterx|
  changeset.tags.each do |k,v|
    xml.tag :k => k, :v => v
  end
  if @comments
    xml.discussion do 
      @comments.each do |comment|
        xml.comment do
          xml.date comment.created_at

          xml.uid comment.author.id
          xml.user comment.author.display_name
          xml.user_url user_url(:display_name => comment.author.display_name, :host => SERVER_URL)

          xml.text comment.body.to_text
          xml.html comment.body.to_html
        end
      end
    end
  end
end