json.partial! "api/root_attributes"

json.api do
  json.version do
    json.minimum Settings.api_version
    json.maximum Settings.api_version
  end
  json.area do
    json.maximum Settings.max_request_area
  end
  json.note_area do
    json.maximum Settings.max_note_request_area
  end
  json.tracepoints do
    json.per_page Settings.tracepoints_per_page
  end
  json.waynodes do
    json.maximum Settings.max_number_of_way_nodes
  end
  json.relationmembers do
    json.maximum Settings.max_number_of_relation_members
  end
  json.changesets do
    json.maximum_elements Changeset::MAX_ELEMENTS
    json.default_query_limit Settings.default_changeset_query_limit
    json.maximum_query_limit Settings.max_changeset_query_limit
  end
  json.notes do
    json.default_query_limit Settings.default_note_query_limit
    json.maximum_query_limit Settings.max_note_query_limit
  end
  json.timeout do
    json.seconds Settings.api_timeout
  end
  json.status do
    json.database @database_status
    json.api @api_status
    json.gpx @gpx_status
  end
end

json.policy do
  json.imagery do
    json.blacklist(Settings.imagery_blacklist) do |url_regex|
      json.regex url_regex.to_s
    end
  end
end
