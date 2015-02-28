require "test_helper"

class UserLoginTest < ActionDispatch::IntegrationTest
  fixtures :users, :user_blocks

  def setup
    OmniAuth.config.test_mode = true
  end

  def teardown
    OmniAuth.config.mock_auth[:openid] = nil
    OmniAuth.config.mock_auth[:google] = nil
    OmniAuth.config.test_mode = false
  end

  def test_login_email_password_normal
    user = users(:normal_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.email, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.email, :password => "test", :referer => "/history"
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
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.email.upcase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.email.upcase, :password => "test", :referer => "/history"
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
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.email.titlecase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.email.titlecase, :password => "test", :referer => "/history"
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
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.email, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.email, :password => "test", :referer => "/history"
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
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.email.upcase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.email.upcase, :password => "test", :referer => "/history"
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
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.email.titlecase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.email.titlecase, :password => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "test2"
  end

  def test_login_email_password_inactive
    user = users(:inactive_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.email, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.email, :password => "test2", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "confirm"
  end

  def test_login_email_password_inactive_upcase
    user = users(:inactive_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.email.upcase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.email.upcase, :password => "test2", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "confirm"
  end

  def test_login_email_password_inactive_titlecase
    user = users(:inactive_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.email.titlecase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.email.titlecase, :password => "test2", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "confirm"
  end

  def test_login_email_password_suspended
    user = users(:suspended_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.email, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.email, :password => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_email_password_suspended_upcase
    user = users(:suspended_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.email.upcase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.email.upcase, :password => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_email_password_suspended_titlecase
    user = users(:suspended_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.email.titlecase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.email.titlecase, :password => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_email_password_blocked
    user = users(:blocked_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.email, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.email, :password => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user_blocks/show"
  end

  def test_login_email_password_blocked_upcase
    user = users(:blocked_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.email.upcase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.email.upcase, :password => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user_blocks/show"
  end

  def test_login_email_password_blocked_titlecase
    user = users(:blocked_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.email.titlecase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.email.titlecase, :password => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user_blocks/show"
  end

  def test_login_username_password_normal
    user = users(:normal_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.display_name, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.display_name, :password => "test", :referer => "/history"
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
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.display_name.upcase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.display_name.upcase, :password => "test", :referer => "/history"
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
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.display_name.titlecase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.display_name.titlecase, :password => "test", :referer => "/history"
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
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.display_name, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.display_name, :password => "test", :referer => "/history"
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
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.display_name.upcase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.display_name.upcase, :password => "test", :referer => "/history"
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
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.display_name.titlecase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.display_name.titlecase, :password => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "test2"
  end

  def test_login_username_password_inactive
    user = users(:inactive_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.display_name, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.display_name, :password => "test2", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "confirm"
  end

  def test_login_username_password_inactive_upcase
    user = users(:inactive_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.display_name.upcase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.display_name.upcase, :password => "test2", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "confirm"
  end

  def test_login_username_password_inactive_titlecase
    user = users(:inactive_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.display_name.titlecase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.display_name.titlecase, :password => "test2", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "confirm"
  end

  def test_login_username_password_suspended
    user = users(:suspended_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.display_name, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.display_name, :password => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_username_password_suspended_upcase
    user = users(:suspended_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.display_name.upcase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.display_name.upcase, :password => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_username_password_suspended_titlecase
    user = users(:suspended_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.display_name.titlecase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.display_name.titlecase, :password => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_username_password_blocked
    user = users(:blocked_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.display_name, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.display_name, :password => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user_blocks/show"
  end

  def test_login_username_password_blocked_upcase
    user = users(:blocked_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.display_name.upcase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.display_name.upcase, :password => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user_blocks/show"
  end

  def test_login_username_password_blocked_titlecase
    user = users(:blocked_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.display_name.titlecase, :password => "wrong", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"

    post "/login", :username => user.display_name.titlecase, :password => "test", :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user_blocks/show"
  end

  def test_login_email_password_remember_me
    user = users(:normal_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.email, :password => "test", :remember_me => true, :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "test"
    assert session.key?(:_remember_for)
  end

  def test_login_username_password_remember_me
    user = users(:normal_user)

    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success

    post "/login", :username => user.display_name, :password => "test", :remember_me => true, :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "test"
    assert session.key?(:_remember_for)
  end

  def test_login_openid_success
    OmniAuth.config.add_mock(:openid, :uid => "http://localhost:1123/john.doe")

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true, :referer => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    post "/login", :openid_url => "http://localhost:1123/john.doe", :referer => "/history"
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

  def test_login_openid_remember_me
    OmniAuth.config.add_mock(:openid, :uid => "http://localhost:1123/john.doe")

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true, :referer => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    post "/login", :openid_url => "http://localhost:1123/john.doe", :remember_me_openid => true, :referer => "/history"
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
    assert session.key?(:_remember_for)
  end

  def test_login_openid_connection_failed
    OmniAuth.config.mock_auth[:openid] = :connection_failed

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true, :referer => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    post "/login", :openid_url => "http://localhost:1123/john.doe", :referer => "/history"
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

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true, :referer => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    post "/login", :openid_url => "http://localhost:1123/john.doe", :referer => "/history"
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

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true, :referer => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    post "/login", :openid_url => "http://localhost:1123/fred.bloggs", :referer => "/history"
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

  def test_login_google_success
    OmniAuth.config.add_mock(:google, :uid => "123456789", :extra => {
                               :id_info => { "openid_id" => "http://localhost:1123/fred.bloggs" }
                             })

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "google", :origin => "/login")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "google")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "googleuser"
  end

  def test_login_google_connection_failed
    OmniAuth.config.mock_auth[:google] = :connection_failed

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "google", :origin => "/login")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "google")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_failure_path(:strategy => "google", :message => "connection_failed", :origin => "/login")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", "Connection to authentication provider failed"
    assert_select "span.username", false
  end

  def test_login_google_invalid_credentials
    OmniAuth.config.mock_auth[:google] = :invalid_credentials

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "google", :origin => "/login")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "google")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_failure_path(:strategy => "google", :message => "invalid_credentials", :origin => "/login")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", "Invalid authentication credentials"
    assert_select "span.username", false
  end

  def test_login_google_unknown
    OmniAuth.config.add_mock(:google, :uid => "987654321", :extra => {
                               :id_info => { "openid_id" => "http://localhost:1123/fred.bloggs" }
                             })

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "google", :origin => "/login")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "google")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user/new"
    assert_select "span.username", false
  end

  def test_login_google_upgrade
    OmniAuth.config.add_mock(:google, :uid => "987654321", :extra => {
                               :id_info => { "openid_id" => "http://localhost:1123/john.doe" }
                             })

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "google", :origin => "/login")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "google")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "openIDuser"

    user = User.find_by_display_name("openIDuser")
    assert_equal "google", user.auth_provider
    assert_equal "987654321", user.auth_uid
  end
end
