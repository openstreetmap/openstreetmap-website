# frozen_string_literal: true

xml.instruct! :xml, :version => "1.0"

xml.osm(OSM::API.new.xml_root_attributes) do |osm|
  osm.gpx_changes(:last_id => @last_id) do |changes|
    @events.each do |event|
      changes.change(:id => event.id, :gpx_id => event.gpx_id, :action => event.action, :timestamp => event.created_at.xmlschema)
    end
  end
end
