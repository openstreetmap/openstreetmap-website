xml.instruct!

xml.rss("version" => "2.0", 
        "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
        "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
        "xmlns:georss" => "http://www.georss.org/georss") do
  xml.channel do
    xml.title t("trace.georss.title")
    xml.description t("trace.georss.title")
    xml.link url_for(:controller => :trace, :action => :list, :only_path => false)

    xml.image do
      xml.url image_path("mag_map-rss2.0.png")
      xml.title t("trace.georss.title")
      xml.width 100
      xml.height 100
      xml.link url_for(:controller => :trace, :action => :list, :only_path => false)
    end

    @traces.each do |trace|
      xml.item do
        xml.title trace.name

        xml.link url_for(:controller => :trace, :action => :view, :id => trace.id, :display_name => trace.user.display_name, :only_path => false)
        xml.guid url_for(:controller => :trace, :action => :view, :id => trace.id, :display_name => trace.user.display_name, :only_path => false)

        xml.description do
          xml.cdata! render(:partial => "description", :object => trace, :formats => [ :html ])
        end

        xml.dc :creator, trace.user.display_name

        xml.pubDate trace.timestamp.to_s(:rfc822)

        if trace.latitude and trace.longitude
          xml.geo :lat, trace.latitude
          xml.geo :long, trace.longitude
          xml.georss :point, "#{trace.latitude} #{trace.longitude}"
        end
      end
    end
  end
end
