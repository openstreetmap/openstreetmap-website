xml.item do
  location_string = Rails.cache.fetch("location_description_#{note.lat}_#{note.lon}_#{locale}") do
    describe_location note.lat, note.lon, 14, locale
  end 
  if note.status == "closed"
    xml.title t('note.rss.closed', :place => location_string)	
  elsif note.comments.length > 1
    xml.title t('note.rss.comment', :place => location_string)
  else
    xml.title t('note.rss.new', :place => location_string)
  end

  xml.link browse_note_url(note)
  xml.guid note_url(note)
  xml.description render(:partial => "description", :object => note, :formats => [ :html ])
  xml.author note.comments.first.author_name
  xml.pubDate note.updated_at.to_s(:rfc822)
  xml.geo :lat, note.lat
  xml.geo :long, note.lon
  xml.georss :point, "#{note.lat} #{note.lon}"
end
