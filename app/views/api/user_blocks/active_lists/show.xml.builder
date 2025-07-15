xml.instruct!

xml.osm(OSM::API.new.xml_root_attributes) do |osm|
  osm << (render(:partial => "api/user_blocks/user_block", :collection => @user_blocks) || "")
end
