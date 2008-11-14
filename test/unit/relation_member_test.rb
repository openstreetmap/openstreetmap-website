require File.dirname(__FILE__) + '/../test_helper'

class RelationMemberTest < Test::Unit::TestCase
  fixtures :current_relation_members
  set_fixture_class :current_relation_members => RelationMember
  
  def test_relation_member_count
    assert_equal 5, RelationMember.count
  end
  
end
