require "test_helper"

class FriendTest < ActiveSupport::TestCase
  api_fixtures

  def test_friend_count
    create(:friend)
    assert_equal 1, Friend.count
  end
end
