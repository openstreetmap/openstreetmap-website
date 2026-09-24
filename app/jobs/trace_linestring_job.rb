# frozen_string_literal: true

class TraceLinestringJob < ApplicationJob
  queue_as :traces

  # Converts the points of a trace into linestrings, one per segment of
  # max_points_per_track_segment points. Z is the altitude and M is the time in
  # seconds, -Infinity when the point has no timestamp (some traces from before
  # 2009). Those points go at the end of the track, as they do when gps_points is
  # sorted by timestamp. -Infinity because 0 is a real value (devices with the
  # clock set to 1970) and NaN is never equal to itself, so it is easy to get a
  # comparison wrong.
  #
  # A segment also ends when the next point is more than
  # max_distance_between_track_points meters away, so a bad point (for example
  # at 0,0) does not stretch the bounding box of a whole segment, and every
  # max_track_segment_length meters of track, so a long fast track (train, plane)
  # does not produce segments wider than a download bbox.
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
               dense_rank() OVER (PARTITION BY gpx_id, trackid ORDER BY run, part, (row_in_part - 1) / #{Settings.max_points_per_track_segment}) - 1 AS segment
        FROM (
          SELECT gpx_id, trackid, seq, pt, run, part,
                 row_number() OVER (PARTITION BY gpx_id, trackid, run, part ORDER BY seq) AS row_in_part
          FROM (
            /* run is the number of the stretch between two jumps, part the number
               of the max_track_segment_length stretch, jumps not counted */
            SELECT gpx_id, trackid, seq, pt,
                   count(*) FILTER (WHERE jump > #{Settings.max_distance_between_track_points})
                     OVER (PARTITION BY gpx_id, trackid ORDER BY seq) AS run,
                   floor(sum(CASE WHEN jump > #{Settings.max_distance_between_track_points} THEN 0 ELSE jump END)
                           OVER (PARTITION BY gpx_id, trackid ORDER BY seq) / #{Settings.max_track_segment_length}) AS part
            FROM (
              /* seq gives a fixed order, timestamps can repeat. jump is the distance to the previous point */
              SELECT gpx_id, trackid, pt,
                     row_number() OVER (PARTITION BY gpx_id, trackid ORDER BY "timestamp") AS seq,
                     COALESCE(ST_DistanceSphere(pt, lag(pt) OVER (PARTITION BY gpx_id, trackid ORDER BY "timestamp")), 0) AS jump
              FROM (
                /* gps_points saves the coordinates as integers, so we divide them
                   here. When gps_points is gone, the import can use the degrees
                   from the file. */
                SELECT gpx_id, trackid, "timestamp",
                       ST_MakePoint(longitude / #{GeoRecord::SCALE}.0,
                                    latitude / #{GeoRecord::SCALE}.0,
                                    COALESCE(altitude, 0),
                                    COALESCE(EXTRACT(EPOCH FROM "timestamp"), '-infinity')) AS pt
                FROM gps_points
                WHERE gpx_id = $1
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
