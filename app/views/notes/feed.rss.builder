xml.instruct!

xml.rss("version" => "2.0", 
        "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
        "xmlns:georss" => "http://www.georss.org/georss") do
  xml.channel do
    xml.title t('note.rss.title')
    xml.description t('note.rss.description_area', :min_lat => @min_lat, :min_lon => @min_lon, :max_lat => @max_lat, :max_lon => @max_lon )
    xml.link url_for(:controller => "site", :action => "index", :only_path => false)

    @comments.each do |comment|
      location = describe_location(comment.note.lat, comment.note.lon, 14, locale)

      xml.item do
        if comment.event == "closed"
          xml.title t('note.rss.closed', :place => location)
        elsif comment.event == "commented"
          xml.title t('note.rss.comment', :place => location)
        elsif comment.event == "opened"
          xml.title t('note.rss.new', :place => location)
        else
          xml.title "unknown event"
        end
        
        xml.link url_for(:controller => "browse", :action => "note", :id => comment.note.id, :only_path => false)
        xml.guid url_for(:controller => "browse", :action => "note", :id => comment.note.id, :only_path => false)

        description_text = ""

        if comment.event == "commented" and not comment.nil?
          description_text += "<b>Comment:</b><br>"
          description_text += comment.body.to_html
          description_text += "<br>"
        end

        description_text += "<b>Full note:</b><br>"
        description_text += comment.note.flatten_comment("<br>", comment.created_at)

        xml.description description_text 
        xml.author comment.author_name
        xml.pubDate comment.created_at.to_s(:rfc822)
        xml.geo :lat, comment.note.lat
        xml.geo :long, comment.note.lon
        xml.georss :point, "#{comment.note.lat} #{comment.note.lon}"
      end
    end
  end
end
