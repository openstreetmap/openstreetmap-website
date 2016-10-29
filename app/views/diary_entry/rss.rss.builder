xml.instruct!

xml.rss("version" => "2.0",
        "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
        "xmlns:georss" => "http://www.georss.org/georss") do
  xml.channel do
    xml.title @title
    xml.description @description
    xml.link url_for(:action => "list", :host => SERVER_URL)
    xml.image do
      xml.url image_path("mag_map-rss2.0.png")
      xml.title "OpenStreetMap"
      xml.width "100"
      xml.height "100"
      xml.link url_for(:action => "list", :host => SERVER_URL)
    end

    @entries.each do |entry|
      xml.item do
        xml.title entry.title
        xml.link url_for(:action => "view", :id => entry.id, :display_name => entry.user.display_name, :host => SERVER_URL)
        xml.guid url_for(:action => "view", :id => entry.id, :display_name => entry.user.display_name, :host => SERVER_URL)
        xml.description entry.body.to_html
        xml.author entry.user.display_name
        xml.pubDate entry.created_at.to_s(:rfc822)
        xml.comments url_for(:action => "view", :id => entry.id, :display_name => entry.user.display_name, :anchor => "comments", :host => SERVER_URL)

        if entry.latitude && entry.longitude
          xml.geo :lat, entry.latitude.to_s
          xml.geo :long, entry.longitude.to_s
          xml.georss :point, "#{entry.latitude} #{entry.longitude}"
        end
      end
    end
  end
end
