require "test_helper"

class UserLoginTest < ActionDispatch::IntegrationTest
  fixtures :users

  def setup
    OmniAuth.config.test_mode = true
  end

  def teardown
    OmniAuth.config.mock_auth[:openid] = nil
    OmniAuth.config.test_mode = false
  end

  def test_login_email_password_normal
    user = users(:normal_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post "/login", "username" => user.email, "password" => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", "username" => user.email, "password" => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "test"
  end

  def test_login_email_password_normal_upcase
    user = users(:normal_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post "/login", "username" => user.email.upcase, "password" => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", "username" => user.email.upcase, "password" => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "TEST"
  end

  def test_login_email_password_normal_titlecase
    user = users(:normal_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post "/login", "username" => user.email.titlecase, "password" => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", "username" => user.email.titlecase, "password" => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "span.username", false
  end

  def test_login_email_password_public
    user = users(:public_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post "/login", "username" => user.email, "password" => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", "username" => user.email, "password" => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "test2"
  end

  def test_login_email_password_public_upcase
    user = users(:public_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post "/login", "username" => user.email.upcase, "password" => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", "username" => user.email.upcase, "password" => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "test2"
  end

  def test_login_email_password_public_titlecase
    user = users(:public_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post "/login", "username" => user.email.titlecase, "password" => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", "username" => user.email.titlecase, "password" => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "test2"
  end

  def test_login_username_password_normal
    user = users(:normal_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post "/login", "username" => user.display_name, "password" => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", "username" => user.display_name, "password" => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "test"
  end

  def test_login_username_password_normal_upcase
    user = users(:normal_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post "/login", "username" => user.display_name.upcase, "password" => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", "username" => user.display_name.upcase, "password" => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "TEST"
  end

  def test_login_username_password_normal_titlecase
    user = users(:normal_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post "/login", "username" => user.display_name.titlecase, "password" => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", "username" => user.display_name.titlecase, "password" => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "span.username", false
  end

  def test_login_username_password_public
    user = users(:public_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post "/login", "username" => user.display_name, "password" => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", "username" => user.display_name, "password" => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "test2"
  end

  def test_login_username_password_public_upcase
    user = users(:public_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post "/login", "username" => user.display_name.upcase, "password" => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", "username" => user.display_name.upcase, "password" => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "test2"
  end

  def test_login_username_password_public_titlecase
    user = users(:public_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success

    post "/login", "username" => user.display_name.titlecase, "password" => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", "username" => user.display_name.titlecase, "password" => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "test2"
  end

  def test_login_openid_success
    OmniAuth.config.add_mock(:openid, :uid => "http://localhost:1123/john.doe")

    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    post "/login", "openid_url" => "http://localhost:1123/john.doe", :referer => "/history"
    assert_response :redirect
    assert_redirected_to auth_path(:provider => "openid", :openid_url => "http://localhost:1123/john.doe", :origin => "/login")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "openid", :openid_url => "http://localhost:1123/john.doe", :origin => "/login")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "openIDuser"
  end

  def test_login_openid_connection_failed
    OmniAuth.config.mock_auth[:openid] = :connection_failed

    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    post "/login", "openid_url" => "http://localhost:1123/john.doe", :referer => "/history"
    assert_response :redirect
    assert_redirected_to auth_path(:provider => "openid", :openid_url => "http://localhost:1123/john.doe", :origin => "/login")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "openid", :openid_url => "http://localhost:1123/john.doe", :origin => "/login")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_failure_path(:strategy => "openid", :message => "connection_failed", :origin => "/login")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", "Connection to authentication provider failed"
    assert_select "span.username", false
  end

  def test_login_openid_invalid_credentials
    OmniAuth.config.mock_auth[:openid] = :invalid_credentials

    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    post "/login", "openid_url" => "http://localhost:1123/john.doe", :referer => "/history"
    assert_response :redirect
    assert_redirected_to auth_path(:provider => "openid", :openid_url => "http://localhost:1123/john.doe", :origin => "/login")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "openid", :openid_url => "http://localhost:1123/john.doe", :origin => "/login")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_failure_path(:strategy => "openid", :message => "invalid_credentials", :origin => "/login")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", "Invalid authentication credentials"
    assert_select "span.username", false
  end

  def test_login_openid_unknown
    OmniAuth.config.add_mock(:openid, :uid => "http://localhost:1123/fred.bloggs")

    get "/login"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true"
    follow_redirect!
    assert_response :success
    post "/login", "openid_url" => "http://localhost:1123/fred.bloggs", :referer => "/diary"
    assert_response :redirect
    assert_redirected_to auth_path(:provider => "openid", :openid_url => "http://localhost:1123/fred.bloggs", :origin => "/login")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "openid", :openid_url => "http://localhost:1123/fred.bloggs", :origin => "/login")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user/new"
    assert_select "span.username", false
  end
end
