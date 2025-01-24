xml.instruct!

xml.osm(OSM::API.new.xml_root_attributes) do |osm|
  osm << (render(:partial => "bounds", :object => @bounds) || "")
  osm << (render(@nodes) || "")
  osm << (render(@ways) || "")
  osm << (render(@relations) || "")
end
