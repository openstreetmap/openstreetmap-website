require File.dirname(__FILE__) + '/../test_helper'

class RelationTest < ActiveSupport::TestCase
  api_fixtures
  
  def test_relation_count
    assert_equal 6, Relation.count
  end
  
end
