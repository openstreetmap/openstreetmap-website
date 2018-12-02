xml.instruct!

xml.rss("version" => "2.0",
        "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
        "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
        "xmlns:georss" => "http://www.georss.org/georss") do
  xml.channel do
    xml.title @title
    xml.description @description
    xml.link url_for(:action => "index", :only_path => false)
    xml.image do
      xml.url image_url("mag_map-rss2.0.png")
      xml.title @title
      xml.width "100"
      xml.height "100"
      xml.link url_for(:action => "index", :only_path => false)
    end

    @entries.each do |entry|
      xml.item do
        xml.title entry.title
        xml.link diary_entry_url(entry.user, entry, :only_path => false)
        xml.guid diary_entry_url(entry.user, entry, :only_path => false)
        xml.description entry.body.to_html
        xml.dc :creator, entry.user.display_name
        xml.pubDate entry.created_at.to_s(:rfc822)
        xml.comments diary_entry_url(entry.user, entry, :anchor => "comments", :only_path => false)

        if entry.latitude && entry.longitude
          xml.geo :lat, entry.latitude.to_s
          xml.geo :long, entry.longitude.to_s
          xml.georss :point, "#{entry.latitude} #{entry.longitude}"
        end
      end
    end
  end
end
