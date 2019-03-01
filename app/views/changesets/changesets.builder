xml.instruct! :xml, :version => "1.0"

# basic attributes

xml.osm(OSM::API.new.xml_root_attributes) do |osm|
  @changesets.each do |changeset|
     osm << render(:partial => "changesets/changeset.builder", :locals => { :changeset => changeset })
  end
end
