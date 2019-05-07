xml.instruct!

xml.osm(OSM::API.new.xml_root_attributes) do |osm|
  osm << (render(:partial => "api/map/node", :collection => @nodes) || "")
  osm << (render(:partial => "api/map/way", :collection => @ways) || "")
end
