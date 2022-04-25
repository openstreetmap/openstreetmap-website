# create list of permissions
xml.instruct! :xml, :version => "1.0"
xml.osm(OSM::API.new.xml_root_attributes) do
  xml.permissions do
    @permissions.each do |permission|
      xml.permission :name => permission
    end
  end
end
