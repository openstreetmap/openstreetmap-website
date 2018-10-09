require "test_helper"

class UserRolesTest < ActionDispatch::IntegrationTest
  def setup
    stub_hostip_requests
  end

  test "grant" do
    check_fail(:grant, :user, :moderator)
    check_fail(:grant, :moderator_user, :moderator)
    check_success(:grant, :administrator_user, :moderator)
  end

  test "revoke" do
    check_fail(:revoke, :user, :moderator)
    check_fail(:revoke, :moderator_user, :moderator)
    # this other user doesn't have moderator role, so this fails
    check_fail(:revoke, :administrator_user, :moderator)
  end

  private

  def check_fail(action, user, role)
    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "users", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    post "/login", :params => { "username" => create(user).email, "password" => "test", :referer => "/" }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    target_user = create(:user)
    post "/user/#{ERB::Util.u(target_user.display_name)}/role/#{role}/#{action}"
    assert_redirected_to user_path(target_user)

    reset!
  end

  def check_success(action, user, role)
    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "users", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    post "/login", :params => { "username" => create(user).email, "password" => "test", :referer => "/" }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    target_user = create(:user)
    post "/user/#{ERB::Util.u(target_user.display_name)}/role/#{role}/#{action}"
    assert_redirected_to user_path(target_user)

    reset!
  end
end
