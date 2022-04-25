xml.instruct! :xml, :version => "1.0"

xml.osmChange(OSM::API.new.xml_root_attributes) do |osm|
  @created.each do |elt|
    osm.create do |create|
      create << render(elt)
    end
  end
  @modified.each do |elt|
    osm.modify do |modify|
      modify << render(elt)
    end
  end
  @deleted.each do |elt|
    osm.delete do |delete|
      delete << render(elt)
    end
  end
end
