xml.rss("version" => "2.0", 
        "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
        "xmlns:georss" => "http://www.georss.org/georss") do
  xml.channel do
    xml.title @title
    xml.description @description
    xml.link url_for(params.merge({ :only_path => false }))
    xml.image do
      xml.url "http://www.openstreetmap.org/images/mag_map-rss2.0.png"
      xml.title "OpenStreetMap"
      xml.width "100"
      xml.height "100"
      xml.link url_for(params.merge({ :only_path => false }))
    end

    for changeset in @edits
      xml.item do
        xml.title t('browse.changeset.title') + " " + h(changeset.id)
        xml.link url_for(:controller => 'browse', :action => "changeset", :id => changeset.id, :only_path => false)
        xml.guid url_for(:controller => 'browse', :action => "changeset", :id => changeset.id, :only_path => false)
        if changeset.user.data_public?
          xml.author changeset.user.display_name
        end
        if changeset.tags['comment']
          xml.description changeset.tags['comment']
        end
        xml.pubDate changeset.created_at.to_s(:rfc822)
        if changeset.user.data_public?
          xml.comments url_for(:controller => "message", :action => "new", :id => changeset.user.id, :only_path => false)
        end

        unless changeset.min_lat.nil?
          minlon = changeset.min_lon/GeoRecord::SCALE.to_f
          minlat = changeset.min_lat/GeoRecord::SCALE.to_f
          maxlon = changeset.max_lon/GeoRecord::SCALE.to_f
          maxlat = changeset.max_lat/GeoRecord::SCALE.to_f

          # See http://georss.org/Encodings#Geometry
          lower_corner = "#{minlat} #{minlon}"
          upper_corner = "#{maxlat} #{maxlon}"

          xml.georss :box, lower_corner + " " + upper_corner
        end
      end
    end
  end
end
