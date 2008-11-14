require File.dirname(__FILE__) + '/../test_helper'

class WayTagTest < Test::Unit::TestCase
  fixtures :way_tags
  
  
  def test_way_tag_count
    assert_equal 3, WayTag.count
  end
  
end
