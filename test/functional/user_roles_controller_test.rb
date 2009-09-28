require File.dirname(__FILE__) + '/../test_helper'

class UserRolesControllerTest < ActionController::TestCase
  fixtures :users, :user_roles

  test "grant" do
    check_forbidden(:grant, :public_user)
    check_forbidden(:grant, :moderator_user)
    check_success(:grant, :administrator_user)
  end

  test "revoke" do
    check_forbidden(:revoke, :public_user)
    check_forbidden(:revoke, :moderator_user)
    check_success(:revoke, :administrator_user)
  end

  def check_forbidden(action, user)
    UserRole::ALL_ROLES.each do |role|
      u = users(user)
      basic_authorization(u.email, "test")
      
      get(action, {:display_name => users(:second_public_user).display_name, :role => role}, {'user' => u.id})
      assert_response :redirect
      assert_redirected_to "/403.html"
    end
  end

  def check_success(action, user)
    UserRole::ALL_ROLES.each do |role|
      u = users(user)
      basic_authorization(u.email, "test")
      
      get(action, {:display_name => users(:second_public_user).display_name, :role => role}, {'user' => u.id})
      assert_response :success
    end
  end
end
