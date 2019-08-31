xml.instruct! :xml, :version => "1.0"
xml.osm(OSM::API.new.xml_root_attributes.except("version")) do |osm|
  osm.api do |api|
    @versions.each do |version|
      api.version version
    end
  end
end
