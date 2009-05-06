require File.dirname(__FILE__) + '/../test_helper'

class TraceTest < Test::Unit::TestCase
  api_fixtures
  
  def test_trace_count
    assert_equal 2, Trace.count
  end
  
end
