require 'test_helper'

class UserCreationTest < ActionController::IntegrationTest
  fixtures :users

  def test_create_user_duplicate
    get '/user/new'
    assert_response :success
  end
end
