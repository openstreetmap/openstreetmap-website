require 'test_helper'

class UserTokenTest < ActiveSupport::TestCase
  api_fixtures
  fixtures :user_tokens

  def test_user_token_count
    assert_equal 0, UserToken.count
  end
  
end
