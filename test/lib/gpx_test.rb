# frozen_string_literal: true

require "test_helper"
require "gpx"

class GpxTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Write +content+ to a Tempfile with the given +suffix+ and yield its path.
  def with_tempfile(content, suffix: ".xml")
    Tempfile.create(["gpx_test", suffix]) do |f|
      f.write(content)
      f.flush
      yield f.path
    end
  end

  def points_from_kml(content)
    with_tempfile(content, :suffix => ".kml") do |path|
      gpx = GPX::File.new(path)
      gpx.points.to_a
    end
  end

  # ---------------------------------------------------------------------------
  # GPX (regression smoke-test – existing format must still work)
  # ---------------------------------------------------------------------------

  def test_gpx_parse_returns_tracepoints
    path = Rails.root.join("test/gpx/fixtures/a.gpx").to_s
    gpx = GPX::File.new(path)
    pts = gpx.points.to_a

    assert_equal 1, pts.length
    assert_in_delta 1.0, pts.first.latitude,  0.0001
    assert_in_delta 1.0, pts.first.longitude, 0.0001
    assert_equal 0, pts.first.segment
  end

  # ---------------------------------------------------------------------------
  # KML – LineString format (e.g. Traccar exports)
  # ---------------------------------------------------------------------------

  LINESTRING_KML = <<~KML
    <?xml version="1.0" encoding="UTF-8"?>
    <kml xmlns="http://www.opengis.net/kml/2.2">
      <Document>
        <name>Test Device</name>
        <Placemark>
          <name>2008-10-01 10:10 - 2008-10-01 10:12</name>
          <LineString>
            <coordinates>1.0,2.0,100.0 3.0,4.0,200.0 5.0,6.0,300.0</coordinates>
          </LineString>
        </Placemark>
      </Document>
    </kml>
  KML

  def test_kml_linestring_point_count
    pts = points_from_kml(LINESTRING_KML)
    assert_equal 3, pts.length
  end

  def test_kml_linestring_coordinates_are_lon_lat
    # KML coordinates are lon,lat,alt – the parser must swap them for lat/lon
    pts = points_from_kml(LINESTRING_KML)

    assert_in_delta 2.0, pts[0].latitude,  0.0001
    assert_in_delta 1.0, pts[0].longitude, 0.0001

    assert_in_delta 4.0, pts[1].latitude,  0.0001
    assert_in_delta 3.0, pts[1].longitude, 0.0001

    assert_in_delta 6.0, pts[2].latitude,  0.0001
    assert_in_delta 5.0, pts[2].longitude, 0.0001
  end

  def test_kml_linestring_altitude
    pts = points_from_kml(LINESTRING_KML)

    assert_in_delta 100.0, pts[0].altitude, 0.0001
    assert_in_delta 200.0, pts[1].altitude, 0.0001
    assert_in_delta 300.0, pts[2].altitude, 0.0001
  end

  def test_kml_linestring_timestamps_are_sequential
    pts = points_from_kml(LINESTRING_KML)

    assert_not_nil pts[0].timestamp
    assert_not_nil pts[1].timestamp
    assert_not_nil pts[2].timestamp

    # Synthetic timestamps must be 1 second apart
    assert_equal 1, (pts[1].timestamp - pts[0].timestamp).to_i
    assert_equal 1, (pts[2].timestamp - pts[1].timestamp).to_i
  end

  def test_kml_linestring_base_time_from_placemark_name
    pts = points_from_kml(LINESTRING_KML)

    # Placemark name starts with "2008-10-01 10:10"
    expected_base = Time.utc(2008, 10, 1, 10, 10, 0)
    assert_equal expected_base, pts[0].timestamp
  end

  def test_kml_linestring_all_points_same_segment
    pts = points_from_kml(LINESTRING_KML)
    segments = pts.map(&:segment).uniq
    assert_equal 1, segments.length
  end

  def test_kml_linestring_tracksegs_incremented
    with_tempfile(LINESTRING_KML, :suffix => ".kml") do |path|
      gpx = GPX::File.new(path)
      gpx.points.to_a          # consume the enumerator
      assert_equal 1, gpx.tracksegs
    end
  end

  def test_kml_linestring_actual_points_counted
    with_tempfile(LINESTRING_KML, :suffix => ".kml") do |path|
      gpx = GPX::File.new(path)
      gpx.points.to_a
      assert_equal 3, gpx.actual_points
    end
  end

  def test_kml_linestring_possible_points_counted
    with_tempfile(LINESTRING_KML, :suffix => ".kml") do |path|
      gpx = GPX::File.new(path)
      gpx.points.to_a
      assert_equal 3, gpx.possible_points
    end
  end

  def test_kml_linestring_falls_back_to_epoch_when_no_name
    kml = <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
          <Placemark>
            <LineString>
              <coordinates>1.0,2.0,0.0</coordinates>
            </LineString>
          </Placemark>
        </Document>
      </kml>
    KML

    pts = points_from_kml(kml)
    assert_equal 1, pts.length
    assert_equal Time.utc(1970, 1, 1), pts.first.timestamp
  end

  def test_kml_linestring_falls_back_to_epoch_when_name_unparseable
    kml = <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
          <Placemark>
            <name>No date here at all</name>
            <LineString>
              <coordinates>1.0,2.0,0.0</coordinates>
            </LineString>
          </Placemark>
        </Document>
      </kml>
    KML

    pts = points_from_kml(kml)
    assert_equal 1, pts.length
    assert_equal Time.utc(1970, 1, 1), pts.first.timestamp
  end

  def test_kml_linestring_skips_empty_tuples
    kml = <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
          <Placemark>
            <LineString>
              <coordinates>  1.0,2.0,0.0   3.0,4.0,0.0  </coordinates>
            </LineString>
          </Placemark>
        </Document>
      </kml>
    KML

    pts = points_from_kml(kml)
    assert_equal 2, pts.length
  end

  def test_kml_linestring_missing_altitude_defaults_to_zero
    kml = <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
          <Placemark>
            <LineString>
              <coordinates>1.0,2.0</coordinates>
            </LineString>
          </Placemark>
        </Document>
      </kml>
    KML

    pts = points_from_kml(kml)
    assert_equal 1, pts.length
    assert_in_delta 0.0, pts.first.altitude, 0.0001
  end

  def test_kml_linestring_multiple_placemarks
    kml = <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
          <Placemark>
            <LineString>
              <coordinates>1.0,2.0,0.0 3.0,4.0,0.0</coordinates>
            </LineString>
          </Placemark>
          <Placemark>
            <LineString>
              <coordinates>5.0,6.0,0.0</coordinates>
            </LineString>
          </Placemark>
        </Document>
      </kml>
    KML

    pts = points_from_kml(kml)
    assert_equal 3, pts.length
  end

  def test_kml_linestring_multiple_placemarks_increment_tracksegs
    kml = <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
          <Placemark>
            <LineString>
              <coordinates>1.0,2.0,0.0</coordinates>
            </LineString>
          </Placemark>
          <Placemark>
            <LineString>
              <coordinates>3.0,4.0,0.0</coordinates>
            </LineString>
          </Placemark>
        </Document>
      </kml>
    KML

    with_tempfile(kml, :suffix => ".kml") do |path|
      gpx = GPX::File.new(path)
      gpx.points.to_a
      assert_equal 2, gpx.tracksegs
    end
  end

  def test_kml_linestring_rejects_out_of_range_latitude
    kml = <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
          <Placemark>
            <LineString>
              <coordinates>1.0,91.0,0.0</coordinates>
            </LineString>
          </Placemark>
        </Document>
      </kml>
    KML

    # lat=91 is invalid – point should be skipped
    pts = points_from_kml(kml)
    assert_empty pts
  end

  def test_kml_linestring_rejects_out_of_range_longitude
    kml = <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
          <Placemark>
            <LineString>
              <coordinates>181.0,2.0,0.0</coordinates>
            </LineString>
          </Placemark>
        </Document>
      </kml>
    KML

    pts = points_from_kml(kml)
    assert_empty pts
  end

  def test_kml_linestring_enforces_maximum_points
    kml = <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
          <Placemark>
            <LineString>
              <coordinates>1.0,2.0,0.0 3.0,4.0,0.0 5.0,6.0,0.0</coordinates>
            </LineString>
          </Placemark>
        </Document>
      </kml>
    KML

    with_tempfile(kml, :suffix => ".kml") do |path|
      gpx = GPX::File.new(path, :maximum_points => 2)
      assert_raise GPX::FileTooBigError do
        gpx.points.to_a
      end
    end
  end

  # ---------------------------------------------------------------------------
  # KML – gx:Track format (Google Earth extended data)
  # ---------------------------------------------------------------------------

  GX_TRACK_KML = <<~KML
    <?xml version="1.0" encoding="UTF-8"?>
    <kml xmlns="http://www.opengis.net/kml/2.2"
         xmlns:gx="http://www.google.com/kml/ext/2.2">
      <Document>
        <Placemark>
          <gx:Track>
            <when>2008-10-01T10:10:10Z</when>
            <when>2008-10-01T10:10:11Z</when>
            <when>2008-10-01T10:10:12Z</when>
            <gx:coord>1.0 2.0 100.0</gx:coord>
            <gx:coord>3.0 4.0 200.0</gx:coord>
            <gx:coord>5.0 6.0 300.0</gx:coord>
          </gx:Track>
        </Placemark>
      </Document>
    </kml>
  KML

  def test_kml_gx_track_point_count
    pts = points_from_kml(GX_TRACK_KML)
    assert_equal 3, pts.length
  end

  def test_kml_gx_track_coordinates_are_lon_lat
    pts = points_from_kml(GX_TRACK_KML)

    assert_in_delta 2.0, pts[0].latitude,  0.0001
    assert_in_delta 1.0, pts[0].longitude, 0.0001

    assert_in_delta 4.0, pts[1].latitude,  0.0001
    assert_in_delta 3.0, pts[1].longitude, 0.0001
  end

  def test_kml_gx_track_altitude
    pts = points_from_kml(GX_TRACK_KML)

    assert_in_delta 100.0, pts[0].altitude, 0.0001
    assert_in_delta 200.0, pts[1].altitude, 0.0001
    assert_in_delta 300.0, pts[2].altitude, 0.0001
  end

  def test_kml_gx_track_real_timestamps
    pts = points_from_kml(GX_TRACK_KML)

    assert_equal Time.utc(2008, 10, 1, 10, 10, 10), pts[0].timestamp
    assert_equal Time.utc(2008, 10, 1, 10, 10, 11), pts[1].timestamp
    assert_equal Time.utc(2008, 10, 1, 10, 10, 12), pts[2].timestamp
  end

  def test_kml_gx_track_tracksegs_incremented
    with_tempfile(GX_TRACK_KML, :suffix => ".kml") do |path|
      gpx = GPX::File.new(path)
      gpx.points.to_a
      assert_equal 1, gpx.tracksegs
    end
  end

  def test_kml_gx_track_actual_points_counted
    with_tempfile(GX_TRACK_KML, :suffix => ".kml") do |path|
      gpx = GPX::File.new(path)
      gpx.points.to_a
      assert_equal 3, gpx.actual_points
    end
  end

  def test_kml_gx_track_skips_unpaired_when
    kml = <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2"
           xmlns:gx="http://www.google.com/kml/ext/2.2">
        <Document>
          <Placemark>
            <gx:Track>
              <when>2008-10-01T10:10:10Z</when>
              <when>2008-10-01T10:10:11Z</when>
              <gx:coord>1.0 2.0 0.0</gx:coord>
            </gx:Track>
          </Placemark>
        </Document>
      </kml>
    KML

    # Second <when> has no matching <gx:coord> – zip will pair it with nil and
    # the parser must skip it
    pts = points_from_kml(kml)
    assert_equal 1, pts.length
  end

  def test_kml_gx_track_skips_unpaired_coord
    kml = <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2"
           xmlns:gx="http://www.google.com/kml/ext/2.2">
        <Document>
          <Placemark>
            <gx:Track>
              <when>2008-10-01T10:10:10Z</when>
              <gx:coord>1.0 2.0 0.0</gx:coord>
              <gx:coord>3.0 4.0 0.0</gx:coord>
            </gx:Track>
          </Placemark>
        </Document>
      </kml>
    KML

    pts = points_from_kml(kml)
    assert_equal 1, pts.length
  end

  def test_kml_gx_track_skips_invalid_timestamp
    kml = <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2"
           xmlns:gx="http://www.google.com/kml/ext/2.2">
        <Document>
          <Placemark>
            <gx:Track>
              <when>not-a-date</when>
              <gx:coord>1.0 2.0 0.0</gx:coord>
            </gx:Track>
          </Placemark>
        </Document>
      </kml>
    KML

    pts = points_from_kml(kml)
    assert_empty pts
  end

  def test_kml_gx_track_missing_altitude_defaults_to_zero
    kml = <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2"
           xmlns:gx="http://www.google.com/kml/ext/2.2">
        <Document>
          <Placemark>
            <gx:Track>
              <when>2008-10-01T10:10:10Z</when>
              <gx:coord>1.0 2.0</gx:coord>
            </gx:Track>
          </Placemark>
        </Document>
      </kml>
    KML

    pts = points_from_kml(kml)
    assert_equal 1, pts.length
    assert_in_delta 0.0, pts.first.altitude, 0.0001
  end

  def test_kml_gx_track_enforces_maximum_points
    with_tempfile(GX_TRACK_KML, :suffix => ".kml") do |path|
      gpx = GPX::File.new(path, :maximum_points => 2)
      assert_raise GPX::FileTooBigError do
        gpx.points.to_a
      end
    end
  end

  def test_kml_gx_track_multiple_tracks_increment_tracksegs
    kml = <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2"
           xmlns:gx="http://www.google.com/kml/ext/2.2">
        <Document>
          <Placemark>
            <gx:Track>
              <when>2008-10-01T10:10:10Z</when>
              <gx:coord>1.0 2.0 0.0</gx:coord>
            </gx:Track>
          </Placemark>
          <Placemark>
            <gx:Track>
              <when>2008-10-01T10:10:11Z</when>
              <gx:coord>3.0 4.0 0.0</gx:coord>
            </gx:Track>
          </Placemark>
        </Document>
      </kml>
    KML

    with_tempfile(kml, :suffix => ".kml") do |path|
      gpx = GPX::File.new(path)
      gpx.points.to_a
      assert_equal 2, gpx.tracksegs
    end
  end

  # ---------------------------------------------------------------------------
  # KML – mixed document (LineString + gx:Track in the same file)
  # ---------------------------------------------------------------------------

  def test_kml_mixed_linestring_and_gx_track
    kml = <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2"
           xmlns:gx="http://www.google.com/kml/ext/2.2">
        <Document>
          <Placemark>
            <LineString>
              <coordinates>1.0,2.0,0.0 3.0,4.0,0.0</coordinates>
            </LineString>
          </Placemark>
          <Placemark>
            <gx:Track>
              <when>2008-10-01T10:10:10Z</when>
              <gx:coord>5.0 6.0 0.0</gx:coord>
            </gx:Track>
          </Placemark>
        </Document>
      </kml>
    KML

    pts = points_from_kml(kml)
    assert_equal 3, pts.length
  end

  # ---------------------------------------------------------------------------
  # KML detection helpers
  # ---------------------------------------------------------------------------

  def test_kml_detected_by_opengis_namespace
    kml = '<?xml version="1.0"?><kml xmlns="http://www.opengis.net/kml/2.2"></kml>'
    with_tempfile(kml, :suffix => ".kml") do |path|
      gpx = GPX::File.new(path)
      # If it is detected as KML the parser will run without raising a
      # LibXML parse error about missing <trkpt> elements.
      assert_nothing_raised { gpx.points.to_a }
    end
  end

  def test_kml_detected_by_lowercase_kml_tag
    kml = '<?xml version="1.0"?><kml></kml>'
    with_tempfile(kml, :suffix => ".kml") do |path|
      gpx = GPX::File.new(path)
      assert_nothing_raised { gpx.points.to_a }
    end
  end
end
