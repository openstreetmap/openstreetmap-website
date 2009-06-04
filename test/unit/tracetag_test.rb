require File.dirname(__FILE__) + '/../test_helper'

class TracetagTest < ActiveSupport::TestCase
  api_fixtures
  
  def test_tracetag_count
    assert_equal 1, Tracetag.count
  end
  
end
