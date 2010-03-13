xml.instruct!


xml.gpx("version" => "1.1", 
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
	    "xsi:schemaLocation" => "http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd") do

	for bug in @bugs
      xml.wpt("lon" => bug.lon, "lat" => bug.lat) do
		xml.desc do
			xml.cdata! bug.flatten_comment("<hr />")
		end
		xml.extension do
			if bug.status = "open"
				xml.closed "0"
			else
				xml.closed "1"
			end
			xml.id bug.id
		end
      end
	end
end
