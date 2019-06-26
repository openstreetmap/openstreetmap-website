xml.instruct!

xml.osm(OSM::API.new.xml_root_attributes) do |osm|
  osm << (render(:partial => "bounds", :object => @bounds) || "")
  osm << (render(:partial => "node", :collection => @nodes) || "")
  osm << (render(:partial => "way", :collection => @ways) || "")
  osm << (render(:partial => "relation", :collection => @relations) || "")
end
