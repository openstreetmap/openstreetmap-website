module Api
  class TracepointsController < ApiController
    authorize_resource

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
        raise OSM::APIBadUserInput, "The parameter bbox is required" unless params[:bbox]

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
      @points = ordered_points.union_all(unordered_points).offset(offset).limit(Settings.tracepoints_per_page).preload(:trace)

      response.headers["Content-Disposition"] = "attachment; filename=\"tracks.gpx\""

      render :formats => [:gpx]
    end
  end
end
