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

  # Hide the order of non-trackable tracepoints when retrieved using .in_bbox
  # (A more detailed test of this is in test/controllers/api_controller_test.rb)
  def test_tracepoints_in_bbox
    trace = create(:trace, :visibility => "private", :latitude => 5.003, :longitude => 5.003) do |trace|
      create(:tracepoint, :trace => trace, :latitude => (5.003 * GeoRecord::SCALE).to_i, :longitude => (5.003 * GeoRecord::SCALE).to_i, :timestamp => Time.now)
      create(:tracepoint, :trace => trace, :latitude => (5.006 * GeoRecord::SCALE).to_i, :longitude => (5.006 * GeoRecord::SCALE).to_i, :timestamp => Time.now + 1)
      create(:tracepoint, :trace => trace, :latitude => (5.005 * GeoRecord::SCALE).to_i, :longitude => (5.005 * GeoRecord::SCALE).to_i, :timestamp => Time.now + 2)
    end
    bbox = BoundingBox.from_bbox_params(:bbox => "5.0,5.0,5.1,5.1")
    points = Tracepoint.in_bbox(bbox)
    assert points.each_cons(2).all?{ |point, nextpoint|
      point.latitude < nextpoint.latitude
    }
  end

end
