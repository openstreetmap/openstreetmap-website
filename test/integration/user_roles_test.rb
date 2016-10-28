require "test_helper"

class UserRolesTest < ActionDispatch::IntegrationTest
  fixtures :users, :user_roles

  setup do
    stub_request(:get, "http://api.hostip.info/country.php?ip=127.0.0.1")
  end

  test "grant" do
    check_fail(:grant, :public_user, :moderator)
    check_fail(:grant, :moderator_user, :moderator)
    check_success(:grant, :administrator_user, :moderator)
  end

  test "revoke" do
    check_fail(:revoke, :public_user, :moderator)
    check_fail(:revoke, :moderator_user, :moderator)
    # this other user doesn't have moderator role, so this fails
    check_fail(:revoke, :administrator_user, :moderator)
  end

  private

  def check_fail(action, user, role)
    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    post "/login", "username" => users(user).email, "password" => "test", :referer => "/"
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post "/user/#{users(:second_public_user).display_name}/role/#{role}/#{action}"
    assert_redirected_to :controller => "user", :action => "view", :display_name => users(:second_public_user).display_name

    reset!
  end

  def check_success(action, user, role)
    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    post "/login", "username" => users(user).email, "password" => "test", :referer => "/"
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post "/user/#{users(:second_public_user).display_name}/role/#{role}/#{action}"
    assert_redirected_to :controller => "user", :action => "view", :display_name => users(:second_public_user).display_name

    reset!
  end
end
