xml.instruct! :xml, :version => "1.0"
xml.osm(OSM::API.new.xml_root_attributes) do |osm|
  osm << render(:partial => "api_user", :object => @user)
end
