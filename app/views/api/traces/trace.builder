xml.instruct! :xml, :version => "1.0"

# basic attributes

xml.osm(OSM::API.new.xml_root_attributes) do |osm|
  @traces.each do |trace|
    osm << render(:partial => "api/traces/trace.builder", :locals => { :trace => trace })
  end
end
