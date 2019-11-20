xml.instruct!

xml.osm(OSM::API.new.xml_root_attributes) do |osm|
  osm.preferences do |preferences|
    preferences << (render(@user_preferences) || "")
  end
end
