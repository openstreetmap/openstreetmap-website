xml.instruct! :xml, :version => "1.0"
xml.osm(OSM::API.new.xml_root_attributes) do |osm|
  osm.api do |api|
    api.version(:minimum => Settings.api_version, :maximum => Settings.api_version)
    api.area(:maximum => Settings.max_request_area)
    api.note_area(:maximum => Settings.max_note_request_area)
    api.tracepoints(:per_page => Settings.tracepoints_per_page)
    api.waynodes(:maximum => Settings.max_number_of_way_nodes)
    api.changesets(:maximum_elements => Changeset::MAX_ELEMENTS)
    api.timeout(:seconds => Settings.api_timeout)
    api.status(:database => @database_status,
               :api => @api_status,
               :gpx => @gpx_status)
  end
  osm.policy do |policy|
    policy.imagery do |imagery|
      Settings.imagery_blacklist.each do |url_regex|
        imagery.blacklist(:regex => url_regex.to_s)
      end
    end
  end
end
