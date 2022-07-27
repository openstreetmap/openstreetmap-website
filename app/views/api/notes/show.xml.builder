xml.instruct!

xml.osm(OSM::API.new.xml_root_attributes) do |osm|
  osm << render(@note)
end
