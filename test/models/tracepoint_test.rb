require "test_helper"

class TracepointTest < ActiveSupport::TestCase
  def test_timestamp_required
    tracepoint = create(:tracepoint)
    assert tracepoint.valid?
    tracepoint.timestamp = nil
    assert_not tracepoint.valid?
  end

  # Ensure the lat/lon is formatted as a decimal e.g. not 4.0e-05
  def test_lat_lon_xml_format
    tracepoint = build(:tracepoint, :latitude => 0.00004 * GeoRecord::SCALE, :longitude => 0.00008 * GeoRecord::SCALE)

    assert_match(/lat="0.0000400"/, tracepoint.to_xml_node.to_s)
    assert_match(/lon="0.0000800"/, tracepoint.to_xml_node.to_s)
  end

  # Scope trackable_ordered returns only trackable tracepoints
  def test_trackable_ordered
    create(:trace, :visibility => "trackable", :latitude => 6.003, :longitude => 6.003) do |trace|
      create(:tracepoint, :trace => trace, :latitude => (6.003 * GeoRecord::SCALE).to_i, :longitude => (6.003 * GeoRecord::SCALE).to_i)
    end
    create(:trace, :visibility => "private", :latitude => 6.004, :longitude => 6.004) do |trace|
      create(:tracepoint, :trace => trace, :latitude => (6.004 * GeoRecord::SCALE).to_i, :longitude => (6.004 * GeoRecord::SCALE).to_i)
    end
    bbox = BoundingBox.from_bbox_params(:bbox => "6.0,6.0,6.1,6.1")
    points = Tracepoint.bbox(bbox).trackable_ordered
    assert points.size == 1
  end

  # Scope non_trackable_unordered hides the order of non-trackable tracepoints
  def test_non_trackable_unordered
    create(:trace, :visibility => "private", :latitude => 5.003, :longitude => 5.003) do |trace|
      create(:tracepoint, :trace => trace, :latitude => (5.003 * GeoRecord::SCALE).to_i, :longitude => (5.003 * GeoRecord::SCALE).to_i, :timestamp => Time.now)
      create(:tracepoint, :trace => trace, :latitude => (5.006 * GeoRecord::SCALE).to_i, :longitude => (5.006 * GeoRecord::SCALE).to_i, :timestamp => Time.now + 1)
      create(:tracepoint, :trace => trace, :latitude => (5.005 * GeoRecord::SCALE).to_i, :longitude => (5.005 * GeoRecord::SCALE).to_i, :timestamp => Time.now + 2)
    end
    bbox = BoundingBox.from_bbox_params(:bbox => "5.0,5.0,5.1,5.1")
    points = Tracepoint.bbox(bbox).non_trackable_unordered
    points.each_cons(2) do |point, nextpoint|
      assert point.latitude < nextpoint.latitude
    end
  end
end
