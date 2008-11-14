require File.dirname(__FILE__) + '/../test_helper'

class RelationTagTest < Test::Unit::TestCase
  fixtures :current_relation_tags
  set_fixture_class :current_relation_tags => RelationTag
  
  def test_relation_tag_count
    assert_equal 3, RelationTag.count
  end
  
end
