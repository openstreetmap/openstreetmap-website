xml.wpt("lon" => note.lon, "lat" => note.lat) do
  xml.desc do
    xml.cdata! note.flatten_comment("<hr />")
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
