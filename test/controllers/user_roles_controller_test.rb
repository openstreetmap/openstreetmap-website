require 'test_helper'

class UserRolesControllerTest < ActionController::TestCase
  fixtures :users, :user_roles

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/username/role/rolename/grant", :method => :post },
      { :controller => "user_roles", :action => "grant", :display_name => "username", :role => "rolename" }
    )
    assert_routing(
      { :path => "/user/username/role/rolename/revoke", :method => :post },
      { :controller => "user_roles", :action => "revoke", :display_name => "username", :role => "rolename" }
    )
  end

  ##
  # test the grant action
  def test_grant
    # Granting should fail when not logged in
    post :grant, :display_name => users(:normal_user).display_name, :role => "moderator"
    assert_response :forbidden

    # Login as an unprivileged user
    session[:user] = users(:public_user).id

    # Granting should still fail
    post :grant, :display_name => users(:normal_user).display_name, :role => "moderator"
    assert_redirected_to user_path(users(:normal_user).display_name)
    assert_equal "Only administrators can perform user role management, and you are not an administrator.", flash[:error]

    # Login as an administrator
    session[:user] = users(:administrator_user).id

    UserRole::ALL_ROLES.each do |role|
      # Granting a role to a non-existent user should fail
      assert_difference "UserRole.count", 0 do
        post :grant, :display_name => "non_existent_user", :role => role
      end
      assert_response :not_found
      assert_template "user/no_such_user"
      assert_select "h1", "The user non_existent_user does not exist"

      # Granting a role from a user that already has it should fail
      assert_no_difference "UserRole.count" do
        post :grant, :display_name => users(:super_user).display_name, :role => role
      end
      assert_redirected_to user_path(users(:super_user).display_name)
      assert_equal "The user already has role #{role}.", flash[:error]

      # Granting a role to a user that doesn't have it should work...
      assert_difference "UserRole.count", 1 do
        post :grant, :display_name => users(:normal_user).display_name, :role => role
      end
      assert_redirected_to user_path(users(:normal_user).display_name)

      # ...but trying a second time should fail
      assert_no_difference "UserRole.count" do
        post :grant, :display_name => users(:normal_user).display_name, :role => role
      end
      assert_redirected_to user_path(users(:normal_user).display_name)
      assert_equal "The user already has role #{role}.", flash[:error]
    end

    # Granting a non-existent role should fail
    assert_difference "UserRole.count", 0 do
      post :grant, :display_name => users(:normal_user).display_name, :role => "no_such_role"
    end
    assert_redirected_to user_path(users(:normal_user).display_name)
    assert_equal "The string `no_such_role' is not a valid role.", flash[:error]
  end

  ##
  # test the revoke action
  def test_revoke
    # Revoking should fail when not logged in
    post :revoke, :display_name => users(:normal_user).display_name, :role => "moderator"
    assert_response :forbidden

    # Login as an unprivileged user
    session[:user] = users(:public_user).id

    # Revoking should still fail
    post :revoke, :display_name => users(:normal_user).display_name, :role => "moderator"
    assert_redirected_to user_path(users(:normal_user).display_name)
    assert_equal "Only administrators can perform user role management, and you are not an administrator.", flash[:error]

    # Login as an administrator
    session[:user] = users(:administrator_user).id

    UserRole::ALL_ROLES.each do |role|
      # Removing a role from a non-existent user should fail
      assert_difference "UserRole.count", 0 do
        post :revoke, :display_name => "non_existent_user", :role => role
      end
      assert_response :not_found
      assert_template "user/no_such_user"
      assert_select "h1", "The user non_existent_user does not exist"

      # Removing a role from a user that doesn't have it should fail
      assert_no_difference "UserRole.count" do
        post :revoke, :display_name => users(:normal_user).display_name, :role => role
      end
      assert_redirected_to user_path(users(:normal_user).display_name)
      assert_equal "The user does not have role #{role}.", flash[:error]

      # Removing a role' from a user that has it should work...
      assert_difference "UserRole.count", -1 do
        post :revoke, :display_name => users(:super_user).display_name, :role => role
      end
      assert_redirected_to user_path(users(:super_user).display_name)

      # ...but trying a second time should fail
      assert_no_difference "UserRole.count" do
        post :revoke, :display_name => users(:super_user).display_name, :role => role
      end
      assert_redirected_to user_path(users(:super_user).display_name)
      assert_equal "The user does not have role #{role}.", flash[:error]
    end

    # Revoking a non-existent role should fail
    assert_difference "UserRole.count", 0 do
      post :revoke, :display_name => users(:normal_user).display_name, :role => "no_such_role"
    end
    assert_redirected_to user_path(users(:normal_user).display_name)
    assert_equal "The string `no_such_role' is not a valid role.", flash[:error]
  end
end
