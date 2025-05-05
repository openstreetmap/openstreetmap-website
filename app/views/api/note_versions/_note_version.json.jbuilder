json.type "Feature"

json.geometry do
  json.type "Point"
  json.coordinates [note_version.longitude.to_f, note_version.latitude.to_f]
end

json.properties do
  json.id note_version.note_id
  json.version note_version.version
  json.url api_note_url(note_version.note, :format => params[:format])

  if note_version.note.closed?
    json.reopen_url reopen_api_note_url(note_version.note, :format => params[:format])
  else
    json.comment_url comment_api_note_url(note_version.note, :format => params[:format])
    json.close_url close_api_note_url(note_version.note, :format => params[:format])
  end

  json.date_created note_version.note.created_at.to_s
  json.status note_version.status
  json.closed_at note_version.note.closed_at.to_s if note_version.note.closed?

  json.tags note_version.tags unless note_version.tags.empty?

  json.comments(note_version.note.comments) do |comment|
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
