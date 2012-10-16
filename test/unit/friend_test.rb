# encoding: utf-8

require File.dirname(__FILE__) + '/../test_helper'

class FriendTest < ActiveSupport::TestCase
  api_fixtures
  fixtures :friends

  def test_friend_count
    assert_equal 1, Friend.count
  end
  
end
