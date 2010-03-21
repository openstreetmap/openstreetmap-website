xml.instruct!

xml.rss("version" => "2.0", 
        "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
        "xmlns:georss" => "http://www.georss.org/georss") do
  xml.channel do
    xml.title "OpenStreetBugs"
    xml.description t('bugs.rss.description_area', :min_lat => @min_lat, :min_lon => @min_lon, :max_lat => @max_lat, :max_lon => @max_lon )
    xml.link url_for(:controller => "site", :action => "index", :only_path => false)

	for bug in @bugs
      xml.item do
		if bug.status == "closed"
			xml.title t('bugs.rss.closed', :place => bug.nearby_place)	
		else if bug.map_bug_comment.length > 1
			xml.title t('bugs.rss.comment', :place => bug.nearby_place)
		else
			xml.title t('bugs.rss.new', :place => bug.nearby_place)
		end	end
        
        xml.link url_for(:controller => "browse", :action => "bug", :id => bug.id, :only_path => false)
		xml.guid url_for(:controller => "browse", :action => "bug", :id => bug.id, :only_path => false)
        xml.description  htmlize(bug.flatten_comment("<br><br>"))
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
