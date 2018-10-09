xml.instruct! :xml, :version => "1.0"
xml.osm("version" => API_VERSION, "generator" => GENERATOR) do |osm|
  osm << render(:partial => "api_user", :collection => @users)
end
