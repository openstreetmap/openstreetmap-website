xml.instruct!

xml.rss("version" => "2.0",
        "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
        "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
        "xmlns:georss" => "http://www.georss.org/georss") do
  xml.channel do
    xml.title t(".title")
    xml.description t(".title")
    xml.link url_for(:controller => "/traces", :action => :index, :only_path => false)

    xml.image do
      xml.url image_url("mag_map-rss2.0.png")
      xml.title t(".title")
      xml.width 100
      xml.height 100
      xml.link url_for(:controller => "/traces", :action => :index, :only_path => false)
    end

    @traces.each do |trace|
      xml.item do
        xml.title trace.name

        xml.link show_trace_url(trace.user, trace)
        xml.guid show_trace_url(trace.user, trace)

        xml.description do
          xml.cdata! render(:partial => "description", :object => trace, :as => "trace", :formats => [:html])
        end

        xml.dc :creator, trace.user.display_name

        xml.pubDate trace.timestamp.to_fs(:rfc822)

        if trace.latitude && trace.longitude
          xml.geo :lat, trace.latitude
          xml.geo :long, trace.longitude
          xml.georss :point, "#{trace.latitude} #{trace.longitude}"
        end
      end
    end
  end
end
