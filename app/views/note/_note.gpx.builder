xml.wpt("lon" => note.lon, "lat" => note.lat) do
  with_format(:html) do
    xml.desc do
      xml.cdata! render(:partial => "description", :object => note, :format => :html)
    end
  end

  xml.extension do
    if note.status = "open"
      xml.closed "0"
    else
      xml.closed "1"
    end

    xml.id note.id
  end
end
