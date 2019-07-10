xml.instruct! :xml, :version => "1.0"

# basic attributes

xml.osm(OSM::API.new(current_api_version).xml_root_attributes) do |osm|
  osm << render(@changeset)
end
