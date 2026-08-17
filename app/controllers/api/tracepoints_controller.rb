# frozen_string_literal: true

module Api
  class TracepointsController < ApiController
    authorize_resource

    # Get an XML response containing a list of tracepoints that have been uploaded
    # within the specified bounding box. To get the next batch of points, follow
    # the URL given in the Link header of the response.
    def index
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

      points = Tracepoint.bbox(bbox).joins(:trace)
                         .where(:gpx_files => { :visibility => %w[trackable identifiable] })
                         .order(:gpx_id => :desc, :trackid => :asc, :timestamp => :asc)
                         .limit(Settings.tracepoints_per_page).preload(:trace)

      if params[:cursor]
        begin
          gpx_id, trackid, timestamp = parse_cursor(params[:cursor])
        rescue ArgumentError, TypeError
          report_error("The cursor parameter is invalid")
          return
        end

        # Continue after the last point of the previous batch, following the
        # gpx_id desc, trackid asc, timestamp asc ordering of the query above.
        # The gpx_id <= bound is implied by the condition below it, but it gives
        # the planner a single index range and a much better plan.
        points = points.where(<<~SQL.squish, :gpx_id => gpx_id, :trackid => trackid, :timestamp => timestamp)
          gps_points.gpx_id <= :gpx_id
          AND (gps_points.gpx_id < :gpx_id
               OR (gps_points.gpx_id = :gpx_id
                   AND (gps_points.trackid > :trackid
                        OR (gps_points.trackid = :trackid AND gps_points.timestamp > :timestamp))))
        SQL
      else
        page = params.fetch(:page, "0").to_i

        unless page >= 0
          report_error("Page number must be greater than or equal to 0")
          return
        end

        points = points.offset(page * Settings.tracepoints_per_page)
      end

      @points = points.load

      # The Link header is only for cursor pagination, not for the old page parameter.
      if params[:page].blank? && @points.size == Settings.tracepoints_per_page
        next_url = api_tracepoints_url(:bbox => params[:bbox], :cursor => next_cursor(@points.last))
        response.headers["Link"] = "<#{next_url}>; rel=\"next\""
      end
      response.headers["Content-Disposition"] = "attachment; filename=\"tracks.gpx\""

      render :formats => [:gpx]
    end

    private

    def parse_cursor(cursor)
      gpx_id, trackid, timestamp = Base64.urlsafe_decode64(cursor).split("|", 3)

      [Integer(gpx_id), Integer(trackid), Time.at(Integer(timestamp)).utc]
    end

    def next_cursor(point)
      Base64.urlsafe_encode64("#{point.gpx_id}|#{point.trackid}|#{point.timestamp.utc.to_i}", :padding => false)
    end
  end
end
