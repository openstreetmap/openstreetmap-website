require File.dirname(__FILE__) + '/../test_helper'

class UserRolesControllerTest < ActionController::TestCase
  fixtures :users, :user_roles

  test "grant" do
    check_redirect(:grant, :public_user, "/403.html")
    check_redirect(:grant, :moderator_user, "/403.html")
    check_redirect(:grant, :administrator_user, {:controller => :user, :action => :view})
  end

  test "revoke" do
    check_redirect(:revoke, :public_user, "/403.html")
    check_redirect(:revoke, :moderator_user, "/403.html")
    check_redirect(:revoke, :administrator_user, {:controller => :user, :action => :view})
  end

  def check_redirect(action, user, redirect)
    UserRole::ALL_ROLES.each do |role|
      u = users(user)
      basic_authorization(u.email, "test")
      
      get(action, {:display_name => users(:second_public_user).display_name, :role => role}, {'user' => u.id})
      assert_response :redirect
      assert_redirected_to redirect
    end
  end
end
