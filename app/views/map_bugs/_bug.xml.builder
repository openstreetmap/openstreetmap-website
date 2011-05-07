xml.bug("lon" => bug.lon, "lat" => bug.lat) do
  xml.id bug.id
  xml.date_created bug.date_created
  xml.nearby bug.nearby_place
  xml.status bug.status

  if bug.status == "closed"
    xml.date_closed bug.date_closed
  end

  xml.comments do
    bug.map_bug_comment.each do |comment|
      xml.comment do
        xml.date comment.date_created
        xml.uid comment.commenter_id unless comment.commenter_id.nil?
        xml.user comment.commenter_name
        xml.text comment.comment
      end	
    end
  end
end
