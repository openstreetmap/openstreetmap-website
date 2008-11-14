require File.dirname(__FILE__) + '/../test_helper'

class RelationTest < Test::Unit::TestCase
  fixtures :current_relations
  set_fixture_class :current_relations => Relation
  
  def test_relation_count
    assert_equal 3, Relation.count
  end
  
end
