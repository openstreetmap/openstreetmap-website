xml.note("lon" => note.lon, "lat" => note.lat, "version" => note.version) do
  xml.id note.id
  xml.url api_note_url(note, :format => params[:format])

  if note.closed?
    xml.reopen_url reopen_api_note_url(note, :format => params[:format])
  else
    xml.comment_url comment_api_note_url(note, :format => params[:format])
    xml.close_url close_api_note_url(note, :format => params[:format])
  end

  xml.date_created note.created_at
  xml.status note.status

  xml.date_closed note.closed_at if note.closed?

  note.tags.each do |k, v|
    xml.tag(:k => k, :v => v)
  end

  xml.comments do
    note.comments.each do |comment|
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
