# frozen_string_literal: true

class TraceLinestringJob < ApplicationJob
  queue_as :traces

  # Converts the points of a trace into linestrings, one per segment of
  # max_points_per_track_segment points. Z is the altitude and M is the time in seconds.
  #
  # A segment also ends when the next point is more than
  # max_distance_between_track_points meters away, so a bad point (for example
  # at 0,0) does not stretch the bounding box of a whole segment.
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
    sql = <<~SQL.squish
      INSERT INTO gpx_tracks (gpx_id, trackid, segment, geom)
      SELECT gpx_id, trackid, segment,
             CASE WHEN count(*) = 1
                  THEN ST_SetSRID((array_agg(pt))[1], 4326)
                  ELSE ST_SetSRID(ST_MakeLine(pt ORDER BY seq), 4326)
             END
      FROM (
        SELECT gpx_id, trackid, seq, pt,
               dense_rank() OVER (PARTITION BY gpx_id, trackid ORDER BY run, (row_in_run - 1) / #{Settings.max_points_per_track_segment}) - 1 AS segment
        FROM (
          SELECT gpx_id, trackid, seq, pt, run,
                 row_number() OVER (PARTITION BY gpx_id, trackid, run ORDER BY seq) AS row_in_run
          FROM (
            /* run is the number of the stretch between two jumps */
            SELECT gpx_id, trackid, seq, pt,
                   count(*) FILTER (WHERE jump > #{Settings.max_distance_between_track_points})
                     OVER (PARTITION BY gpx_id, trackid ORDER BY seq) AS run
            FROM (
              /* seq gives a fixed order, timestamps can repeat */
              SELECT gpx_id, trackid, pt,
                     row_number() OVER (PARTITION BY gpx_id, trackid ORDER BY "timestamp") AS seq,
                     ST_DistanceSphere(pt, lag(pt) OVER (PARTITION BY gpx_id, trackid ORDER BY "timestamp")) AS jump
              FROM (
                /* gps_points saves the coordinates as integers, so we divide them
                   here. When gps_points is gone, the import can use the degrees
                   from the file. */
                SELECT gpx_id, trackid, "timestamp",
                       ST_MakePoint(longitude / #{GeoRecord::SCALE}.0,
                                    latitude / #{GeoRecord::SCALE}.0,
                                    COALESCE(altitude, 0),
                                    EXTRACT(EPOCH FROM "timestamp")) AS pt
                FROM gps_points
                WHERE gpx_id = $1 AND "timestamp" IS NOT NULL
              ) points
            ) jumps
          ) runs
        ) rows
      ) segments
      GROUP BY gpx_id, trackid, segment
    SQL

    binds = [ActiveRecord::Relation::QueryAttribute.new("gpx_id", trace.id, ActiveRecord::Type::BigInteger.new)]

    segment_count = ApplicationRecord.transaction do
      trace.gpx_tracks.delete_all

      ApplicationRecord.connection.exec_update(sql, "InsertGpxTracks", binds)
    end

    logger.info "No segments inserted for trace #{trace.id}" if segment_count.zero?

    segment_count
  end
end
