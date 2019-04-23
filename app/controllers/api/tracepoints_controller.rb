module Api
  class TracepointsController < ApiController
    authorize_resource

    before_action :check_api_readable
    around_action :api_call_handle_error, :api_call_timeout

    # Get an XML response containing a list of tracepoints that have been uploaded
    # within the specified bounding box, and in the specified page.
    def index
      # retrieve the page number
      page = params["page"].to_s.to_i

      unless page >= 0
        report_error("Page number must be greater than or equal to 0")
        return
      end

      offset = page * Settings.tracepoints_per_page

      # Figure out the bbox
      # check boundary is sane and area within defined
      # see /config/application.yml
      begin
        bbox = BoundingBox.from_bbox_params(params)
        bbox.check_boundaries
        bbox.check_size
      rescue StandardError => e
        report_error(e.message)
        return
      end

      # get all the points
      ordered_points = Tracepoint.bbox(bbox).joins(:trace).where(:gpx_files => { :visibility => %w[trackable identifiable] }).order("gpx_id DESC, trackid ASC, timestamp ASC")
      unordered_points = Tracepoint.bbox(bbox).joins(:trace).where(:gpx_files => { :visibility => %w[public private] }).order("gps_points.latitude", "gps_points.longitude", "gps_points.timestamp")
      points = ordered_points.union_all(unordered_points).offset(offset).limit(Settings.tracepoints_per_page)

      doc = XML::Document.new
      doc.encoding = XML::Encoding::UTF_8
      root = XML::Node.new "gpx"
      root["version"] = "1.0"
      root["creator"] = "OpenStreetMap.org"
      root["xmlns"] = "http://www.topografix.com/GPX/1/0"

      doc.root = root

      # initialise these variables outside of the loop so that they
      # stay in scope and don't get free'd up by the GC during the
      # loop.
      gpx_id = -1
      trackid = -1
      track = nil
      trkseg = nil
      anon_track = nil
      anon_trkseg = nil
      gpx_file = nil
      timestamps = false

      points.each do |point|
        if gpx_id != point.gpx_id
          gpx_id = point.gpx_id
          trackid = -1
          gpx_file = Trace.find(gpx_id)

          if gpx_file.trackable?
            track = XML::Node.new "trk"
            doc.root << track
            timestamps = true

            if gpx_file.identifiable?
              track << (XML::Node.new("name") << gpx_file.name)
              track << (XML::Node.new("desc") << gpx_file.description)
              track << (XML::Node.new("url") << url_for(:controller => "/traces", :action => "show", :display_name => gpx_file.user.display_name, :id => gpx_file.id))
            end
          else
            # use the anonymous track segment if the user hasn't allowed
            # their GPX points to be tracked.
            timestamps = false
            if anon_track.nil?
              anon_track = XML::Node.new "trk"
              doc.root << anon_track
            end
            track = anon_track
          end
        end

        if trackid != point.trackid
          if gpx_file.trackable?
            trkseg = XML::Node.new "trkseg"
            track << trkseg
            trackid = point.trackid
          else
            if anon_trkseg.nil?
              anon_trkseg = XML::Node.new "trkseg"
              anon_track << anon_trkseg
            end
            trkseg = anon_trkseg
          end
        end

        trkseg << point.to_xml_node(timestamps)
      end

      response.headers["Content-Disposition"] = "attachment; filename=\"tracks.gpx\""

      render :xml => doc.to_s
    end
  end
end
