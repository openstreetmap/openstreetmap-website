xml.note("lon" => note_version.longitude, "lat" => note_version.latitude, "version" => note_version.version) do
  xml.id note_version.note_id
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

  xml.comments do
    note_version.note.comments.each do |comment|
      xml.comment do
        xml.date comment.created_at

        if comment.author
          xml.uid comment.author.id
          xml.user comment.author.display_name
          xml.user_url user_url(:display_name => comment.author.display_name, :only_path => false)
        end

        xml.action comment.event

        if comment.body
          xml.text comment.body.to_text
          xml.html comment.body.to_html
        end
      end
    end
  end
end
