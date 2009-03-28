require File.dirname(__FILE__) + '/../test_helper'

class TraceTest < Test::Unit::TestCase
  api_fixtures
  
  def test_trace_count
    assert_equal 1, Trace.count
  end
  
end
