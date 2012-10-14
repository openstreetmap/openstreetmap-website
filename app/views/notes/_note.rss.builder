xml.item do
  if note.status == "closed"
    xml.title t('note.rss.closed', :place => note.nearby_place)	
  elsif note.comments.length > 1
    xml.title t('note.rss.comment', :place => note.nearby_place)
  else
    xml.title t('note.rss.new', :place => note.nearby_place)
  end

  xml.link browse_note_url(note)
  xml.guid note_url(note)
  xml.description render(:partial => "description", :object => note, :formats => [ :html ])
  xml.author note.author_name
  xml.pubDate note.updated_at.to_s(:rfc822)
  xml.geo :lat, note.lat
  xml.geo :long, note.lon
  xml.georss :point, "#{note.lat} #{note.lon}"
end
