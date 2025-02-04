xml.item do
  location = describe_location(note.lat, note.lon, 14, locale)

  if note.closed?
    xml.title t("api.notes.rss.closed", :place => location)
  elsif note.comments.length > 1
    xml.title t("api.notes.rss.commented", :place => location)
  else
    xml.title t("api.notes.rss.opened", :place => location)
  end

  xml.link note_url(note)
  xml.guid api_note_url(note)
  xml.description render(:partial => "description", :object => note, :formats => [:html])

  xml.dc :creator, note.author.display_name unless note.author.nil? || note.author.status == "deleted"

  xml.pubDate note.created_at.to_fs(:rfc822)
  xml.geo :lat, note.lat
  xml.geo :long, note.lon
  xml.georss :point, "#{note.lat} #{note.lon}"
end
