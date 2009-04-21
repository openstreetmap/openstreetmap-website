require File.dirname(__FILE__) + '/../test_helper'

class RelationTest < Test::Unit::TestCase
  api_fixtures
  
  def test_relation_count
    assert_equal 4, Relation.count
  end
  
end
