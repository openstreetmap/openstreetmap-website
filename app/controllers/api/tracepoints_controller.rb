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

      if params[:cursor]
        begin
          gpx_id, trackid, timestamp = parse_cursor(params[:cursor])
        rescue ArgumentError, TypeError
          report_error("The cursor parameter is invalid")
          return
        end

        # Read the bbox in a subquery so the planner uses the tile index.
        # Otherwise the ORDER BY ... LIMIT makes it walk the gpx_id index
        # backwards from the cursor, which can take minutes on a sparse bbox.
        # OFFSET 0 stops PostgreSQL from flattening the subquery.
        candidates = points.where(:gps_points => { :gpx_id => ..gpx_id }).offset(0)

        # Continue after the last point of the previous batch, following the
        # gpx_id desc, trackid asc, timestamp asc ordering of the query below.
        points = Tracepoint.from(candidates, :gps_points)
                           .where(<<~SQL.squish, :gpx_id => gpx_id, :trackid => trackid, :timestamp => timestamp)
                             gps_points.gpx_id < :gpx_id
                             OR (gps_points.gpx_id = :gpx_id
                                 AND (gps_points.trackid > :trackid
                                      OR (gps_points.trackid = :trackid AND gps_points.timestamp > :timestamp)))
                           SQL
      else
        page = params.fetch(:page, "0").to_i

        unless page >= 0
          report_error("Page number must be greater than or equal to 0")
          return
        end

        points = points.offset(page * Settings.tracepoints_per_page)
      end

      points = points.order(:gpx_id => :desc, :trackid => :asc, :timestamp => :asc).preload(:trace)

      if params[:page].blank?
        # One extra point tells if there is a next page.
        loaded = points.limit(Settings.tracepoints_per_page + 1).load
        @points = loaded.first(Settings.tracepoints_per_page)

        # The Link header is only for cursor pagination.
        if loaded.size > Settings.tracepoints_per_page
          @points = without_split_group(points, @points, loaded.last)
          next_url = api_tracepoints_url(:bbox => params[:bbox], :cursor => next_cursor(@points.last))
          response.headers["Link"] = "<#{next_url}>; rel=\"next\""
        end
      else
        @points = points.limit(Settings.tracepoints_per_page).load
      end
      response.headers["Content-Disposition"] = "attachment; filename=\"tracks.gpx\""

      render :formats => [:gpx]
    end

    private

    # Cursor: gpx_id|trackid|unix microseconds. Some points have fractions of a second.
    def parse_cursor(cursor)
      gpx_id, trackid, timestamp = Base64.urlsafe_decode64(cursor).split("|", 3)

      [Integer(gpx_id), Integer(trackid), Time.at(Rational(Integer(timestamp), 1_000_000)).utc]
    end

    def next_cursor(point)
      timestamp = (point.timestamp.utc.to_r * 1_000_000).to_i

      Base64.urlsafe_encode64("#{point.gpx_id}|#{point.trackid}|#{timestamp}", :padding => false)
    end

    # A page must not end inside a group of points with the same gpx_id,
    # trackid and timestamp, since the cursor would skip the rest of the group.
    def without_split_group(points, page, next_point)
      last = page.last
      return page unless same_position?(next_point, last)

      first = page.index { |point| same_position?(point, last) }

      if first.positive?
        page[0...first]
      else
        points.where(:gps_points => { :gpx_id => last.gpx_id, :trackid => last.trackid, :timestamp => last.timestamp }).load
      end
    end

    def same_position?(point, other)
      point.gpx_id == other.gpx_id && point.trackid == other.trackid && point.timestamp == other.timestamp
    end
  end
end
