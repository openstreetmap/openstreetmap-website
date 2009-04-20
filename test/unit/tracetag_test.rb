require File.dirname(__FILE__) + '/../test_helper'

class TracetagTest < Test::Unit::TestCase
  api_fixtures
  
  def test_tracetag_count
    assert_equal 1, Tracetag.count
  end
  
end
