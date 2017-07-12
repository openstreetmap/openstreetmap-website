xml.instruct!

xml.gpx("version" => "1.1",
        "creator" => "OpenStreetMap.org",
        "xmlns" => "http://www.topografix.com/GPX/1/1",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation" => "http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd") do
  xml << render(:partial => "note", :object => @note)
end
