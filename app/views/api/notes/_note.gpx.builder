# frozen_string_literal: true

xml.wpt("lon" => note.lon, "lat" => note.lat) do
  xml.time note.created_at.to_fs(:iso8601)
  xml.name t("notes.show.title", :id => note.id)

  xml.desc do
    xml.cdata! render(:partial => "description", :object => note, :formats => [:html])
  end

  xml.link("href" => note_url(note, :only_path => false))

  xml.extensions do
    xml.id note.id
    xml.url api_note_url(note, :format => params[:format])

    if note.closed?
      xml.reopen_url reopen_api_note_url(note, :format => params[:format])
    else
      xml.comment_url comment_api_note_url(note, :format => params[:format])
      xml.close_url close_api_note_url(note, :format => params[:format])
    end

    xml.date_created note.created_at
    xml.date_updated note.updated_at
    xml.status note.status

    xml.date_closed note.closed_at if note.closed?
  end
end
