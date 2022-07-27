json.type "Feature"

json.geometry do
  json.type "Point"
  json.coordinates [note.lon.to_f, note.lat.to_f]
end

json.properties do
  json.id note.id
  json.url note_url(note, :format => params[:format])

  if note.closed?
    json.reopen_url reopen_note_url(note, :format => params[:format])
  else
    json.comment_url comment_note_url(note, :format => params[:format])
    json.close_url close_note_url(note, :format => params[:format])
  end

  json.date_created note.created_at.to_s
  json.status note.status
  json.closed_at note.closed_at.to_s if note.closed?

  json.comments(note.comments) do |comment|
    json.date comment.created_at.to_s

    if comment.author
      json.uid comment.author.id
      json.user comment.author.display_name
      json.user_url user_url(:display_name => comment.author.display_name, :only_path => false)
    end

    json.action comment.event

    if comment.body
      json.text comment.body.to_text
      json.html comment.body.to_html
    end
  end
end
