xml.item do
  location = describe_location(note.lat, note.lon, 14, locale)

  if note.closed?
    xml.title t("note.rss.closed", :place => location)
  elsif note.comments.length > 1
    xml.title t("note.rss.commented", :place => location)
  else
    xml.title t("note.rss.opened", :place => location)
  end

  xml.link browse_note_url(note)
  xml.guid note_url(note)
  xml.description render(:partial => "description", :object => note, :formats => [:html])

  xml.dc :creator, note.author.display_name if note.author

  xml.pubDate note.updated_at.to_s(:rfc822)
  xml.geo :lat, note.lat
  xml.geo :long, note.lon
  xml.georss :point, "#{note.lat} #{note.lon}"
end
