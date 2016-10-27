require "test_helper"

class UserLoginTest < ActionDispatch::IntegrationTest
  fixtures :users, :user_roles

  def setup
    OmniAuth.config.test_mode = true
  end

  def teardown
    OmniAuth.config.mock_auth[:openid] = nil
    OmniAuth.config.mock_auth[:google] = nil
    OmniAuth.config.mock_auth[:facebook] = nil
    OmniAuth.config.mock_auth[:windowslive] = nil
    OmniAuth.config.mock_auth[:github] = nil
    OmniAuth.config.test_mode = false
  end

  def test_login_email_password_normal
    user = users(:normal_user)

    try_password_login user.email, "test"

    assert_template "changeset/history"
    assert_select "span.username", "test"
  end

  def test_login_email_password_normal_upcase
    user = users(:normal_user)

    try_password_login user.email.upcase, "test"

    assert_template "changeset/history"
    assert_select "span.username", "TEST"
  end

  def test_login_email_password_normal_titlecase
    user = users(:normal_user)

    try_password_login user.email.titlecase, "test"

    assert_template "login"
    assert_select "span.username", false
  end

  def test_login_email_password_public
    user = users(:public_user)

    try_password_login user.email, "test"

    assert_template "changeset/history"
    assert_select "span.username", "test2"
  end

  def test_login_email_password_public_upcase
    user = users(:public_user)

    try_password_login user.email.upcase, "test"

    assert_template "changeset/history"
    assert_select "span.username", "test2"
  end

  def test_login_email_password_public_titlecase
    user = users(:public_user)

    try_password_login user.email.titlecase, "test"

    assert_template "changeset/history"
    assert_select "span.username", "test2"
  end

  def test_login_email_password_inactive
    user = users(:inactive_user)

    try_password_login user.email, "test2"

    assert_template "confirm"
    assert_select "span.username", false
  end

  def test_login_email_password_inactive_upcase
    user = users(:inactive_user)

    try_password_login user.email.upcase, "test2"

    assert_template "confirm"
    assert_select "span.username", false
  end

  def test_login_email_password_inactive_titlecase
    user = users(:inactive_user)

    try_password_login user.email.titlecase, "test2"

    assert_template "confirm"
    assert_select "span.username", false
  end

  def test_login_email_password_suspended
    user = users(:suspended_user)

    try_password_login user.email, "test"

    assert_template "login"
    assert_select "span.username", false
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_email_password_suspended_upcase
    user = users(:suspended_user)

    try_password_login user.email.upcase, "test"

    assert_template "login"
    assert_select "span.username", false
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_email_password_suspended_titlecase
    user = users(:suspended_user)

    try_password_login user.email.titlecase, "test"

    assert_template "login"
    assert_select "span.username", false
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_email_password_blocked
    user = users(:blocked_user)
    create(:user_block, :needs_view, :user => user)

    try_password_login user.email, "test"

    assert_template "user_blocks/show"
    assert_select "span.username", "blocked"
  end

  def test_login_email_password_blocked_upcase
    user = users(:blocked_user)
    create(:user_block, :needs_view, :user => user)

    try_password_login user.email.upcase, "test"

    assert_template "user_blocks/show"
    assert_select "span.username", "blocked"
  end

  def test_login_email_password_blocked_titlecase
    user = users(:blocked_user)
    create(:user_block, :needs_view, :user => user)

    try_password_login user.email.titlecase, "test"

    assert_template "user_blocks/show"
    assert_select "span.username", "blocked"
  end

  def test_login_username_password_normal
    user = users(:normal_user)

    try_password_login user.display_name, "test"

    assert_template "changeset/history"
    assert_select "span.username", "test"
  end

  def test_login_username_password_normal_upcase
    user = users(:normal_user)

    try_password_login user.display_name.upcase, "test"

    assert_template "changeset/history"
    assert_select "span.username", "TEST"
  end

  def test_login_username_password_normal_titlecase
    user = users(:normal_user)

    try_password_login user.display_name.titlecase, "test"

    assert_template "login"
    assert_select "span.username", false
  end

  def test_login_username_password_public
    user = users(:public_user)

    try_password_login user.display_name, "test"

    assert_template "changeset/history"
    assert_select "span.username", "test2"
  end

  def test_login_username_password_public_upcase
    user = users(:public_user)

    try_password_login user.display_name.upcase, "test"

    assert_template "changeset/history"
    assert_select "span.username", "test2"
  end

  def test_login_username_password_public_titlecase
    user = users(:public_user)

    try_password_login user.display_name.titlecase, "test"

    assert_template "changeset/history"
    assert_select "span.username", "test2"
  end

  def test_login_username_password_inactive
    user = users(:inactive_user)

    try_password_login user.display_name, "test2"

    assert_template "confirm"
    assert_select "span.username", false
  end

  def test_login_username_password_inactive_upcase
    user = users(:inactive_user)

    try_password_login user.display_name.upcase, "test2"

    assert_template "confirm"
    assert_select "span.username", false
  end

  def test_login_username_password_inactive_titlecase
    user = users(:inactive_user)

    try_password_login user.display_name.titlecase, "test2"

    assert_template "confirm"
    assert_select "span.username", false
  end

  def test_login_username_password_suspended
    user = users(:suspended_user)

    try_password_login user.display_name, "test"

    assert_template "login"
    assert_select "span.username", false
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_username_password_suspended_upcase
    user = users(:suspended_user)

    try_password_login user.display_name.upcase, "test"

    assert_template "login"
    assert_select "span.username", false
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_username_password_suspended_titlecase
    user = users(:suspended_user)

    try_password_login user.display_name.titlecase, "test"

    assert_template "login"
    assert_select "span.username", false
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_username_password_blocked
    user = users(:blocked_user)
    create(:user_block, :needs_view, :user => user)

    try_password_login user.display_name.upcase, "test"

    assert_template "user_blocks/show"
    assert_select "span.username", "blocked"
  end

  def test_login_username_password_blocked_upcase
    user = users(:blocked_user)
    create(:user_block, :needs_view, :user => user)

    try_password_login user.display_name, "test"

    assert_template "user_blocks/show"
    assert_select "span.username", "blocked"
  end

  def test_login_username_password_blocked_titlecase
    user = users(:blocked_user)
    create(:user_block, :needs_view, :user => user)

    try_password_login user.display_name.titlecase, "test"

    assert_template "user_blocks/show"
    assert_select "span.username", "blocked"
  end

  def test_login_email_password_remember_me
    user = users(:normal_user)

    try_password_login user.email, "test", "yes"

    assert_template "changeset/history"
    assert_select "span.username", "test"
    assert session.key?(:_remember_for)
  end

  def test_login_username_password_remember_me
    user = users(:normal_user)

    try_password_login user.display_name, "test", "yes"

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
    assert_redirected_to auth_path(:provider => "openid", :openid_url => "http://localhost:1123/john.doe", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "openid", :openid_url => "http://localhost:1123/john.doe", :origin => "/login?referer=%2Fhistory", :referer => "/history")
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
    assert_redirected_to auth_path(:provider => "openid", :openid_url => "http://localhost:1123/john.doe", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "openid", :openid_url => "http://localhost:1123/john.doe", :origin => "/login?referer=%2Fhistory", :referer => "/history")
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
    assert_redirected_to auth_path(:provider => "openid", :openid_url => "http://localhost:1123/john.doe", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "openid", :openid_url => "http://localhost:1123/john.doe", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_failure_path(:strategy => "openid", :message => "connection_failed", :origin => "/login?referer=%2Fhistory")
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
    assert_redirected_to auth_path(:provider => "openid", :openid_url => "http://localhost:1123/john.doe", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "openid", :openid_url => "http://localhost:1123/john.doe", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_failure_path(:strategy => "openid", :message => "invalid_credentials", :origin => "/login?referer=%2Fhistory")
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
    assert_redirected_to auth_path(:provider => "openid", :openid_url => "http://localhost:1123/fred.bloggs", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "openid", :openid_url => "http://localhost:1123/fred.bloggs", :origin => "/login?referer=%2Fhistory", :referer => "/history")
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
    get auth_path(:provider => "google", :origin => "/login?referer=%2Fhistory", :referer => "/history")
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
    get auth_path(:provider => "google", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "google")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_failure_path(:strategy => "google", :message => "connection_failed", :origin => "/login?referer=%2Fhistory")
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
    get auth_path(:provider => "google", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "google")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_failure_path(:strategy => "google", :message => "invalid_credentials", :origin => "/login?referer=%2Fhistory")
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
    get auth_path(:provider => "google", :origin => "/login?referer=%2Fhistory", :referer => "/history")
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
    get auth_path(:provider => "google", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "google")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "openIDuser"

    user = User.find_by(:display_name => "openIDuser")
    assert_equal "google", user.auth_provider
    assert_equal "987654321", user.auth_uid
  end

  def test_login_facebook_success
    OmniAuth.config.add_mock(:facebook, :uid => "123456789")

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "facebook", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "facebook")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "facebookuser"
  end

  def test_login_facebook_connection_failed
    OmniAuth.config.mock_auth[:facebook] = :connection_failed

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "facebook", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "facebook")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_failure_path(:strategy => "facebook", :message => "connection_failed", :origin => "/login?referer=%2Fhistory")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", "Connection to authentication provider failed"
    assert_select "span.username", false
  end

  def test_login_facebook_invalid_credentials
    OmniAuth.config.mock_auth[:facebook] = :invalid_credentials

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "facebook", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "facebook")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_failure_path(:strategy => "facebook", :message => "invalid_credentials", :origin => "/login?referer=%2Fhistory")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", "Invalid authentication credentials"
    assert_select "span.username", false
  end

  def test_login_facebook_unknown
    OmniAuth.config.add_mock(:facebook, :uid => "987654321")

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "facebook", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "facebook")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user/new"
    assert_select "span.username", false
  end

  def test_login_windowslive_success
    OmniAuth.config.add_mock(:windowslive, :uid => "123456789")

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "windowslive", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "windowslive", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "windowsliveuser"
  end

  def test_login_windowslive_connection_failed
    OmniAuth.config.mock_auth[:windowslive] = :connection_failed

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "windowslive", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "windowslive", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_failure_path(:strategy => "windowslive", :message => "connection_failed", :origin => "/login?referer=%2Fhistory")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", "Connection to authentication provider failed"
    assert_select "span.username", false
  end

  def test_login_windowslive_invalid_credentials
    OmniAuth.config.mock_auth[:windowslive] = :invalid_credentials

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "windowslive", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "windowslive", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_failure_path(:strategy => "windowslive", :message => "invalid_credentials", :origin => "/login?referer=%2Fhistory")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", "Invalid authentication credentials"
    assert_select "span.username", false
  end

  def test_login_windowslive_unknown
    OmniAuth.config.add_mock(:windowslive, :uid => "987654321")

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "windowslive", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "windowslive", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user/new"
    assert_select "span.username", false
  end

  def test_login_github_success
    OmniAuth.config.add_mock(:github, :uid => "123456789")

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "github", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "github", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", "githubuser"
  end

  def test_login_github_connection_failed
    OmniAuth.config.mock_auth[:github] = :connection_failed

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "github", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "github", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_failure_path(:strategy => "github", :message => "connection_failed", :origin => "/login?referer=%2Fhistory")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", "Connection to authentication provider failed"
    assert_select "span.username", false
  end

  def test_login_github_invalid_credentials
    OmniAuth.config.mock_auth[:github] = :invalid_credentials

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "github", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "github", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_failure_path(:strategy => "github", :message => "invalid_credentials", :origin => "/login?referer=%2Fhistory")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", "Invalid authentication credentials"
    assert_select "span.username", false
  end

  def test_login_github_unknown
    OmniAuth.config.add_mock(:github, :uid => "987654321")

    get "/login", :referer => "/history"
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "github", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "github", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user/new"
    assert_select "span.username", false
  end

  private

  def try_password_login(username, password, remember_me = nil)
    get "/login"
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "input#username", 1 do
      assert_select "[value]", false
    end
    assert_select "input#password", 1 do
      assert_select "[value=?]", ""
    end
    assert_select "input#remember_me", 1 do
      assert_select "[checked]", false
    end

    post "/login", :username => username, :password => "wrong", :remember_me => remember_me, :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "input#username", 1 do
      assert_select "[value=?]", username
    end
    assert_select "input#password", 1 do
      assert_select "[value=?]", ""
    end
    assert_select "input#remember_me", 1 do
      assert_select "[checked]", remember_me == "yes"
    end

    post "/login", :username => username, :password => password, :remember_me => remember_me, :referer => "/history"
    assert_response :redirect
    follow_redirect!
    assert_response :success
  end
end
