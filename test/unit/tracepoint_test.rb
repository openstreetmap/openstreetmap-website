require File.dirname(__FILE__) + '/../test_helper'

class TracepointTest < Test::Unit::TestCase
  fixtures :gps_points
  set_fixture_class :gps_points => Tracepoint
  
  def test_tracepoint_count
    assert_equal 1, Tracepoint.count
  end
  
end
