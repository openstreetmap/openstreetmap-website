require File.dirname(__FILE__) + '/../test_helper'

class RelationMemberTest < Test::Unit::TestCase
  api_fixtures
  
  def test_relation_member_count
    assert_equal 5, RelationMember.count
  end
  
end
