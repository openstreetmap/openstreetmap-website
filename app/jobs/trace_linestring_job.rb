# frozen_string_literal: true

class TraceLinestringJob < ApplicationJob
  queue_as :traces

  # Converts the points of a trace into linestrings, one per segment of
  # max_points_per_track_segment points. Z is the altitude and M is the time in seconds.
  #
  # A track with one point is saved as a point, because a line needs two.
  # All traces are converted, whatever their visibility.
  #
  # The job can run again for the same trace (a retry or a re-import). The delete
  # and the insert run in one transaction, so the trace is left with only its
  # current points.
  #
  # Segments do not share the border point. To draw a full track, join them in order
  # by trackid and segment.
  #
  # Returns the number of segments written.
  def perform(trace)
    sql = ApplicationRecord.sanitize_sql_array([<<~SQL.squish, trace.id])
      INSERT INTO gpx_tracks (gpx_id, trackid, segment, geom)
      SELECT gpx_id, trackid, segment,
             CASE WHEN count(*) = 1
                  THEN ST_SetSRID((array_agg(pt))[1], 4326)
                  ELSE ST_SetSRID(ST_MakeLine(pt ORDER BY "timestamp"), 4326)
             END
      FROM (
        SELECT gpx_id, trackid, "timestamp",
               (row_number() OVER (PARTITION BY gpx_id, trackid ORDER BY "timestamp") - 1) / #{Settings.max_points_per_track_segment} AS segment,
               /* gps_points saves the coordinates as integers, so we divide them
                  here. When gps_points is gone, the import can use the degrees
                  from the file. */
               ST_MakePoint(longitude / #{GeoRecord::SCALE}.0,
                            latitude / #{GeoRecord::SCALE}.0,
                            COALESCE(altitude, 0),
                            EXTRACT(EPOCH FROM "timestamp")) AS pt
        FROM gps_points
        WHERE gpx_id = ? AND "timestamp" IS NOT NULL
      ) points
      GROUP BY gpx_id, trackid, segment
    SQL

    segment_count = ApplicationRecord.transaction do
      trace.gpx_tracks.delete_all

      ApplicationRecord.connection.exec_update(sql, "InsertGpxTracks")
    end

    logger.info "No segments inserted for trace #{trace.id}" if segment_count.zero?

    segment_count
  end
end
