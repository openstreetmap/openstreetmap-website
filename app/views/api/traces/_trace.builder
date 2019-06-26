# basic attributes

attrs = {
  "id" => trace.id,
  "name" => trace.name,
  "user" => trace.user.display_name,
  "visibility" => trace.visibility,
  "pending" => trace.inserted ? "false" : "true",
  "timestamp" => trace.timestamp.xmlschema
}

if trace.inserted
  attrs["lat"] = trace.latitude.to_s
  attrs["lon"] = trace.longitude.to_s
end

xml.gpx_file(attrs) do |trace_xml_node|
  trace_xml_node.description(trace.description)
  trace.tags.each do |t|
    trace_xml_node.tag(t.tag)
  end
end
