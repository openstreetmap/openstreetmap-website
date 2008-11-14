require File.dirname(__FILE__) + '/../test_helper'

class TracetagTest < Test::Unit::TestCase
  fixtures :gpx_file_tags
  set_fixture_class :gpx_file_tags => Tracetag
  
  def test_tracetag_count
    assert_equal 1, Tracetag.count
  end
  
end
