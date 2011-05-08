xml.bug("lon" => bug.lon, "lat" => bug.lat) do
  xml.id bug.id
  xml.date_created bug.created_at
  xml.nearby bug.nearby_place
  xml.status bug.status

  if bug.status == "closed"
    xml.date_closed bug.closed_at
  end

  xml.comments do
    bug.comments.each do |comment|
      xml.comment do
        xml.date comment.created_at
        xml.uid comment.author_id unless comment.author_id.nil?
        xml.user comment.author_name
        xml.text comment.body
      end	
    end
  end
end
