xml.instruct!

xml.bugs do
	for bug in @bugs
		xml.bug("lon" => bug.lon, "lat" => bug.lat) do
			xml.id bug.id
			xml.date_created bug.date_created
			xml.nearby bug.nearby_place
			xml.status bug.status
			if bug.status == "closed"
				xml.date_closed bug.date_closed
			end
			xml.comments do
				for comment in bug.map_bug_comment
					xml.comment do
						xml.date comment.date_created
						if !comment.commenter_id.nil?
							xml.uid comment.commenter_id
							xml.user comment.user.display_name	
						else
							xml.user comment.commenter_name
						end
						xml.text comment.comment
					end	
				end
			end
		end
	end
end
