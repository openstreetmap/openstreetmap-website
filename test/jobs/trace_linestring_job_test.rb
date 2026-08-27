# frozen_string_literal: true

require "test_helper"

class TraceLinestringJobTest < ActiveJob::TestCase
  def test_track_with_several_points_becomes_a_linestring
    trace = create(:trace)
    create_points(trace, 3)

    assert_equal 1, TraceLinestringJob.perform_now(trace)
    assert_equal [["ST_LineString", 3]], segments(trace)
  end

  def test_track_with_one_point_becomes_a_point
    trace = create(:trace)
    create_points(trace, 1)

    assert_equal 1, TraceLinestringJob.perform_now(trace)
    assert_equal [["ST_Point", 1]], segments(trace)
  end

  def test_coordinates_are_saved_in_degrees
    trace = create(:trace)
    timestamp = Time.utc(2026, 1, 1)
    create(:tracepoint, :trace => trace, :latitude => 123_456_789, :longitude => -770_123_456,
                        :altitude => 100.5, :timestamp => timestamp)
    create(:tracepoint, :trace => trace, :latitude => 123_456_790, :longitude => -770_123_455,
                        :altitude => 101.5, :timestamp => timestamp + 1)

    TraceLinestringJob.perform_now(trace)

    lon, lat, altitude, time = first_point(trace)

    assert_in_delta(-77.0123456, lon, 0.0000001)
    assert_in_delta(12.3456789, lat, 0.0000001)
    assert_in_delta(100.5, altitude, 0.001)
    assert_equal(timestamp.to_i, time)
  end

  def test_each_track_gets_its_own_row
    trace = create(:trace)
    create_points(trace, 2, 1)
    create_points(trace, 2, 2)

    assert_equal 2, TraceLinestringJob.perform_now(trace)
    assert_equal [1, 2], trace.gpx_tracks.order(:trackid).map(&:trackid)
  end

  def test_track_is_split_into_segments
    trace = create(:trace)
    create_points(trace, 5)

    with_settings(:max_points_per_track_segment => 2) do
      assert_equal 3, TraceLinestringJob.perform_now(trace)
    end

    assert_equal [["ST_LineString", 2], ["ST_LineString", 2], ["ST_Point", 1]], segments(trace)
    assert_equal [0, 1, 2], trace.gpx_tracks.order(:segment).map(&:segment)
  end

  def test_old_segments_are_replaced
    trace = create(:trace)
    create_points(trace, 3)
    TraceLinestringJob.perform_now(trace)

    create_points(trace, 2, 1, 3)
    TraceLinestringJob.perform_now(trace)

    assert_equal [["ST_LineString", 5]], segments(trace)
  end

  def test_traces_of_any_visibility_are_converted
    %w[identifiable trackable public private].each do |visibility|
      trace = create(:trace, :without_validations, :visibility => visibility)
      create_points(trace, 2)

      assert_equal 1, TraceLinestringJob.perform_now(trace), "#{visibility} trace was not converted"
    end
  end

  private

  def create_points(trace, count, trackid = 1, offset = 0)
    count.times do |index|
      create(:tracepoint, :trace => trace, :trackid => trackid,
                          :latitude => (1 * GeoRecord::SCALE) + offset + index,
                          :longitude => (1 * GeoRecord::SCALE) + offset + index,
                          :timestamp => Time.now.utc + offset + index)
    end
  end

  # Geometry type and number of points of every segment, in segment order.
  def segments(trace)
    GpxTrack.where(:gpx_id => trace.id)
            .order(:trackid, :segment)
            .pluck(Arel.sql("ST_GeometryType(geom)"), Arel.sql("ST_NPoints(geom)"))
  end

  # Longitude, latitude, altitude and time of the first point of a trace.
  def first_point(trace)
    GpxTrack.where(:gpx_id => trace.id)
            .pick(Arel.sql("ST_X(ST_PointN(geom, 1))"), Arel.sql("ST_Y(ST_PointN(geom, 1))"),
                  Arel.sql("ST_Z(ST_PointN(geom, 1))"), Arel.sql("ST_M(ST_PointN(geom, 1))"))
  end
end
