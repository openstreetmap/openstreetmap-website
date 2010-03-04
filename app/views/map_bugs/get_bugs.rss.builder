xml.instruct!

xml.rss("version" => "2.0", 
        "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
        "xmlns:georss" => "http://www.georss.org/georss") do
  xml.channel do
    xml.title "OpenStreetBugs"
    xml.description "A list of bugs, reported, commented on or closed in your area"
    xml.link url_for(:controller => "site", :action => "index", :only_path => false)

	for bug in @bugs
      xml.item do
		if bug.status == "closed"
			xml.title "Closed bug"	
		else if bug.map_bug_comment.length > 1
			xml.title "Commented on bug"
		else
			xml.title "Created bug"
		end	end
        
        xml.link url_for(:controller => "site", :action => "index", :only_path => false)
        xml.description  bug.flatten_comment("|")
		if (!bug.map_bug_comment.empty?)
	        xml.author bug.map_bug_comment[-1].commenter_name
		end
        xml.pubDate bug.last_changed.to_s(:rfc822)
          xml.geo :lat, bug.lat
          xml.geo :long, bug.lon
          xml.georss :point, "#{bug.lat} #{bug.lon}"
      end
	end
  end
end
