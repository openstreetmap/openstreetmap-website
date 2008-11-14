require File.dirname(__FILE__) + '/../test_helper'

class WayTagTest < Test::Unit::TestCase
  fixtures :current_way_tags
  set_fixture_class :current_way_tags => WayTag
  
  def test_way_tag_count
    assert_equal 3, WayTag.count
  end
  
end
