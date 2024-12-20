xml.instruct!

xml.osm(OSM::API.new.xml_root_attributes) do |osm|
  xml.tag! "messages" do
    osm << (render(@messages) || "")
  end
end
