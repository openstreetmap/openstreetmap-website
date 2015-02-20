require "test_helper"

class RelationMemberTest < ActiveSupport::TestCase
  api_fixtures

  def test_relation_member_count
    assert_equal 9, RelationMember.count
  end
end
