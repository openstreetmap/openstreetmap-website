require File.dirname(__FILE__) + '/../test_helper'

class TraceTest < Test::Unit::TestCase
  fixtures :gpx_files
  set_fixture_class :gpx_files => Trace
  
  def test_trace_count
    assert_equal 1, Trace.count
  end
  
end
