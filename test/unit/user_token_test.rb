require File.dirname(__FILE__) + '/../test_helper'

class UserTokenTest < Test::Unit::TestCase
  fixtures :users
  
  def test_user_token_count
    assert_equal 0, UserToken.count
  end
  
end
