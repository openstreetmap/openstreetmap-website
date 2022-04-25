require "test_helper"

class OsmTest < ActiveSupport::TestCase
  def test_mercator
    proj = OSM::Mercator.new(0, 0, 1, 1, 100, 200)
    assert_in_delta(50, proj.x(0.5), 0.01)
    assert_in_delta(100, proj.y(0.5), 0.01)
  end

  def test_mercator_collapsed_bbox
    proj = OSM::Mercator.new(0, 0, 0, 0, 100, 200)
    assert_in_delta(50, proj.x(0), 0.01)
    assert_in_delta(100, proj.y(0), 0.01)
  end
end
