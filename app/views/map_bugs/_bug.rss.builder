xml.item do
  if bug.status == "closed"
    xml.title t('bugs.rss.closed', :place => bug.nearby_place)	
  elsif bug.map_bug_comment.length > 1
    xml.title t('bugs.rss.comment', :place => bug.nearby_place)
  else
    xml.title t('bugs.rss.new', :place => bug.nearby_place)
  end

  xml.link url_for(:controller => "browse", :action => "bug", :id => bug.id, :only_path => false)
  xml.guid url_for(:controller => "map_bugs", :action => "read", :id => bug.id, :only_path => false)
  xml.description  htmlize(bug.flatten_comment("<br><br>"))

  unless bug.map_bug_comment.empty?
    xml.author bug.map_bug_comment[-1].commenter_name
  end

  xml.pubDate bug.last_changed.to_s(:rfc822)
  xml.geo :lat, bug.lat
  xml.geo :long, bug.lon
  xml.georss :point, "#{bug.lat} #{bug.lon}"
end
