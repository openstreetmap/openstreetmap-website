xml.instruct!

xml.osm(:version => API_VERSION, :generator => GENERATOR) do |osm|
  osm << render(:partial => "changeset", :object => @changeset)
end
