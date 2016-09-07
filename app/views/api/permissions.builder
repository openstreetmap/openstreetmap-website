# create list of permissions
xml.instruct! :xml, :version => "1.0"
xml.osm("version" => API_VERSION.to_s, "generator" => "OpenStreetMap Server") do
  xml.permissions do
    @permissions.each do |permission|
      xml.permission :name => permission
    end
  end
end
