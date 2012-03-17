xml.instruct!

xml.rss("version" => "2.0", 
        "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
        "xmlns:georss" => "http://www.georss.org/georss") do
  xml.channel do
    xml.title @title
    xml.description @description
    xml.link url_for(:action => "list", :only_path => false)
    xml.image do
      xml.url "http://www.openstreetmap.org/images/mag_map-rss2.0.png"
      xml.title "OpenStreetMap"
      xml.width "100"
      xml.height "100"
      xml.link url_for(:action => "list", :only_path => false)
    end

    for entry in @entries
      xml.item do
        xml.title h(entry.title)
        xml.link url_for(:action => "view", :id => entry.id, :display_name => entry.user.display_name, :only_path => false)
        xml.guid url_for(:action => "view", :id => entry.id, :display_name => entry.user.display_name, :only_path => false)
        xml.description entry.body.to_html
        xml.author entry.user.display_name
        xml.pubDate entry.created_at.to_s(:rfc822)
        xml.comments url_for(:action => "view", :id => entry.id, :display_name => entry.user.display_name, :anchor => "comments", :only_path => false)
        
        if entry.latitude and entry.longitude
          xml.geo :lat, entry.latitude.to_s
          xml.geo :long, entry.longitude.to_s
          xml.georss :point, "#{entry.latitude.to_s} #{entry.longitude.to_s}"
        end
      end
    end
  end
end
