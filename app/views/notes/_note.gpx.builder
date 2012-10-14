xml.wpt("lon" => note.lon, "lat" => note.lat) do
  xml.desc do
    xml.cdata! render(:partial => "description", :object => note, :formats => [ :html ])
  end

  xml.extension do
    if note.status = "open"
      xml.closed "0"
    else
      xml.closed "1"
    end

    xml.id note.id
    xml.url note_url(note, :format => params[:format])
    xml.comment_url comment_note_url(note, :format => params[:format])
    xml.close_url close_note_url(note, :format => params[:format])
  end
end
