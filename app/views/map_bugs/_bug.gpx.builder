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
