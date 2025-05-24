xml.wpt("lon" => note_version.longitude, "lat" => note_version.latitude) do
  xml.time note_version.note.created_at.to_fs(:iso8601)
  xml.name t("notes.show.title", :id => note_version.note_id)

  xml.desc do
    xml.cdata! render(:partial => "description", :object => note_version.note, :formats => [:html])
  end

  xml.link("href" => note_url(note_version.note, :only_path => false))

  xml.extensions do
    xml.id note_version.note_id
    xml.version note_version.version
    xml.url api_note_url(note_version.note, :format => params[:format])

    if note_version.note.closed?
      xml.reopen_url reopen_api_note_url(note_version.note, :format => params[:format])
    else
      xml.comment_url comment_api_note_url(note_version.note, :format => params[:format])
      xml.close_url close_api_note_url(note_version.note, :format => params[:format])
    end

    xml.date_created note_version.note.created_at
    xml.status note_version.status

    xml.date_closed note_version.note.closed_at if note_version.note.closed?

    note_version.tags.each do |k, v|
      xml.tag(:k => k, :v => v)
    end
  end
end
