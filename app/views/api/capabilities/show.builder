xml.instruct! :xml, :version => "1.0"
xml.osm(OSM::API.new.xml_root_attributes) do |osm|
  osm.api do |api|
    api.version(:minimum => API_VERSION.to_s, :maximum => API_VERSION.to_s)
    api.area(:maximum => MAX_REQUEST_AREA.to_s)
    api.note_area(:maximum => MAX_NOTE_REQUEST_AREA.to_s)
    api.tracepoints(:per_page => TRACEPOINTS_PER_PAGE.to_s)
    api.waynodes(:maximum => MAX_NUMBER_OF_WAY_NODES.to_s)
    api.changesets(:maximum_elements => Changeset::MAX_ELEMENTS.to_s)
    api.timeout(:seconds => API_TIMEOUT.to_s)
    api.status(:database => @database_status.to_s,
               :api => @api_status.to_s,
               :gpx => @gpx_status.to_s)
  end
  osm.policy do |policy|
    policy.imagery do |imagery|
      IMAGERY_BLACKLIST.each do |url_regex|
        imagery.blacklist(:regex => url_regex.to_s)
      end
    end
  end
end
