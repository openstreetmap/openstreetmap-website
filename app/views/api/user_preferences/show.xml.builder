xml.instruct!

xml.osm(OSM::API.new.xml_root_attributes) do |osm|
  osm.preferences do |preferences|
    preferences << (render(@preference) || "")
  end
end
