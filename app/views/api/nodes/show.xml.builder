xml.instruct!

xml.osm(OSM::API.new.xml_root_attributes) do |osm|
  osm << (render(:partial => "api/map/node", :collection => @nodes) || "")
end
