xml.instruct!

xml.rss("version" => "2.0",
        "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
        "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
        "xmlns:georss" => "http://www.georss.org/georss") do
  xml.channel do
    xml.title t("api.notes.rss.title")
    xml.description t("api.notes.rss.description_area", :min_lat => @min_lat, :min_lon => @min_lon, :max_lat => @max_lat, :max_lon => @max_lon)
    xml.link url_for(:controller => "/site", :action => "index", :only_path => false)

    @comments.each do |comment|
      location = describe_location(comment.note.lat, comment.note.lon, 14, locale)

      xml.item do
        xml.title t("api.notes.rss.#{comment.event}", :place => location)

        xml.link url_for(:controller => "/browse", :action => "note", :id => comment.note.id, :anchor => "c#{comment.id}", :only_path => false)
        xml.guid url_for(:controller => "/browse", :action => "note", :id => comment.note.id, :anchor => "c#{comment.id}", :only_path => false)

        xml.description do
          xml.cdata! render(:partial => "entry", :object => comment, :formats => [:html])
        end

        xml.dc :creator, comment.author.display_name if comment.author

        xml.pubDate comment.created_at.to_s(:rfc822)
        xml.geo :lat, comment.note.lat
        xml.geo :long, comment.note.lon
        xml.georss :point, "#{comment.note.lat} #{comment.note.lon}"
      end
    end
  end
end
