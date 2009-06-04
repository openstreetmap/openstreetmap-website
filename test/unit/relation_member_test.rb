require File.dirname(__FILE__) + '/../test_helper'

class RelationMemberTest < ActiveSupport::TestCase
  api_fixtures
  
  def test_relation_member_count
    assert_equal 6, RelationMember.count
  end
  
end
