xml.wpt("lon" => note.lon, "lat" => note.lat) do
  xml.desc do
    xml.cdata! render(:partial => "description", :object => note, :formats => [ :html ])
  end

  xml.extension do
    xml.id note.id
    xml.url note_url(note, :format => params[:format])

    if note.closed?
      xml.reopen_url reopen_note_url(note, :format => params[:format])
    else
      xml.comment_url comment_note_url(note, :format => params[:format])
      xml.close_url close_note_url(note, :format => params[:format])
    end

    xml.date_created note.created_at
    xml.status note.status

    if note.status == "closed"
      xml.date_closed note.closed_at
    end
  end
end
