require File.dirname(__FILE__) + '/../test_helper'

class CurrentNodeTagTest < Test::Unit::TestCase
  fixtures :current_node_tags, :nodes
  
  def test_tag_count
    assert_equal 3, NodeTag.count
  end
  
end
