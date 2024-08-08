require "test_helper"

class CommunityMemberTest < ActiveSupport::TestCase
  def test_community_validations
    validate({}, true)

    validate({ :community_id => nil }, false)
    validate({ :community_id => "" }, false)

    validate({ :user_id => nil }, false)
    validate({ :user_id => "" }, false)

    # validate({ :role => "overlord" }, false)
  end
end
