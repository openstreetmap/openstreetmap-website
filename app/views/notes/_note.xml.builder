xml.note("lon" => note.lon, "lat" => note.lat) do
  xml.id note.id
  xml.date_created note.created_at
  xml.nearby note.nearby_place
  xml.status note.status

  if note.status == "closed"
    xml.date_closed note.closed_at
  end

  xml.comments do
    note.comments.each do |comment|
      xml.comment do
        xml.date comment.created_at
        xml.uid comment.author_id unless comment.author_id.nil?
        xml.user comment.author_name
        xml.text comment.body
      end	
    end
  end
end
