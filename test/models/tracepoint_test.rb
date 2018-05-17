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

    assert_match /lat="0.0000400"/, tracepoint.to_xml_node.to_s
    assert_match /lon="0.0000800"/, tracepoint.to_xml_node.to_s
  end
end
