# frozen_string_literal: true

xml.instruct!

xml.gpx("version" => "1.0",
        "creator" => "OpenStreetMap.org",
        "xmlns" => "http://www.topografix.com/GPX/1/0") do
  # initialise these variables outside of the loop so that they
  # stay in scope and don't get free'd up by the GC during the
  # loop.
  gpx_id = -1
  trackid = -1
  tracks = []
  track = nil
  trkseg = nil

  @points.each do |point|
    if gpx_id != point.gpx_id
      gpx_id = point.gpx_id
      trackid = -1

      track = {}
      track["trksegs"] = []
      tracks << track

      if point.trace.identifiable?
        track["name"] = point.trace.name
        track["desc"] = point.trace.description
        track["url"] = url_for(:controller => "/traces", :action => "show", :display_name => point.trace.user.display_name, :id => point.trace.id)
      end
    end

    if trackid != point.trackid
      trkseg = []
      track["trksegs"] << trkseg
      trackid = point.trackid
    end

    trkseg << point
  end

  tracks.each do |trk|
    xml.trk do
      if trk.key?("name")
        xml.name trk["name"]
        xml.desc trk["desc"]
        xml.url trk["url"]
      end
      trk["trksegs"].each do |trksg|
        xml.trkseg do
          trksg.each do |tracepoint|
            xml.trkpt("lat" => tracepoint.lat.to_s, "lon" => tracepoint.lon.to_s) do
              xml.time tracepoint.timestamp.xmlschema
            end
          end
        end
      end
    end
  end
end
