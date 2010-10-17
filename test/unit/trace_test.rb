require File.dirname(__FILE__) + '/../test_helper'

class TraceTest < ActiveSupport::TestCase
  api_fixtures
  
  def test_trace_count
    assert_equal 5, Trace.count
  end
  
end
