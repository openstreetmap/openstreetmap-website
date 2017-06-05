require "test_helper"

class UserLoginTest < ActionDispatch::IntegrationTest
  def setup
    OmniAuth.config.test_mode = true
  end

  def teardown
    OmniAuth.config.mock_auth[:openid] = nil
    OmniAuth.config.mock_auth[:google] = nil
    OmniAuth.config.mock_auth[:facebook] = nil
    OmniAuth.config.mock_auth[:windowslive] = nil
    OmniAuth.config.mock_auth[:github] = nil
    OmniAuth.config.mock_auth[:wikipedia] = nil
    OmniAuth.config.test_mode = false
  end

  # It's possible to have multiple accounts in the database with only differences
  # in email case, for hysterical raisins. We need to bypass the validation checks to
  # create users like this nowadays.
  def test_login_email_password_duplicate
    # Attempt to log in as one user, it should work
    user = create(:user)
    _uppercase_user = build(:user, :email => user.email.upcase).tap { |u| u.save(:validate => false) }

    try_password_login user.email, "test"

    assert_template "changeset/history"
    assert_select "span.username", user.display_name
  end

  def test_login_email_password_duplicate_upcase
    # Attempt to log in as the uppercase_user, it should also work
    user = create(:user)
    uppercase_user = build(:user, :email => user.email.upcase).tap { |u| u.save(:validate => false) }

    try_password_login uppercase_user.email, "test"

    assert_template "changeset/history"
    assert_select "span.username", uppercase_user.display_name
  end

  def test_login_email_password_duplicate_titlecase
    # When there's no exact match for case, and two possible users, it should fail
    user = create(:user)
    _uppercase_user = build(:user, :email => user.email.upcase).tap { |u| u.save(:validate => false) }

    try_password_login user.email.titlecase, "test"

    assert_template "login"
    assert_select "span.username", false
  end

  # When there are no duplicate emails, any variation of cases should work
  def test_login_email_password
    user = create(:user)

    try_password_login user.email, "test"

    assert_template "changeset/history"
    assert_select "span.username", user.display_name
  end

  def test_login_email_password_upcase
    user = create(:user)

    try_password_login user.email.upcase, "test"

    assert_template "changeset/history"
    assert_select "span.username", user.display_name
  end

  def test_login_email_password_titlecase
    user = create(:user)

    try_password_login user.email.titlecase, "test"

    assert_template "changeset/history"
    assert_select "span.username", user.display_name
  end

  def test_login_email_password_pending
    user = create(:user, :pending)

    try_password_login user.email, "test"

    assert_template "confirm"
    assert_select "span.username", false
  end

  def test_login_email_password_pending_upcase
    user = create(:user, :pending)

    try_password_login user.email.upcase, "test"

    assert_template "confirm"
    assert_select "span.username", false
  end

  def test_login_email_password_pending_titlecase
    user = create(:user, :pending)

    try_password_login user.email.titlecase, "test"

    assert_template "confirm"
    assert_select "span.username", false
  end

  def test_login_email_password_suspended
    user = create(:user, :suspended)

    try_password_login user.email, "test"

    assert_template "login"
    assert_select "span.username", false
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_email_password_suspended_upcase
    user = create(:user, :suspended)

    try_password_login user.email.upcase, "test"

    assert_template "login"
    assert_select "span.username", false
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_email_password_suspended_titlecase
    user = create(:user, :suspended)

    try_password_login user.email.titlecase, "test"

    assert_template "login"
    assert_select "span.username", false
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_email_password_blocked
    user = create(:user)
    create(:user_block, :needs_view, :user => user)

    try_password_login user.email, "test"

    assert_template "user_blocks/show"
    assert_select "span.username", user.display_name
  end

  def test_login_email_password_blocked_upcase
    user = create(:user)
    create(:user_block, :needs_view, :user => user)

    try_password_login user.email.upcase, "test"

    assert_template "user_blocks/show"
    assert_select "span.username", user.display_name
  end

  def test_login_email_password_blocked_titlecase
    user = create(:user)
    create(:user_block, :needs_view, :user => user)

    try_password_login user.email.titlecase, "test"

    assert_template "user_blocks/show"
    assert_select "span.username", user.display_name
  end

  # As above, it's possible to have multiple accounts in the database with only
  # differences in display_name case, for hysterical raisins. We need to bypass
  # the validation checks to create users like this nowadays.
  def test_login_username_password_duplicate
    # Attempt to log in as one user, it should work
    user = create(:user)
    _uppercase_user = build(:user, :display_name => user.display_name.upcase).tap { |u| u.save(:validate => false) }

    try_password_login user.display_name, "test"

    assert_template "changeset/history"
    assert_select "span.username", user.display_name
  end

  def test_login_username_password_duplicate_upcase
    # Attempt to log in as the uppercase_user, it should also work
    user = create(:user)
    uppercase_user = build(:user, :display_name => user.display_name.upcase).tap { |u| u.save(:validate => false) }

    try_password_login uppercase_user.display_name, "test"

    assert_template "changeset/history"
    assert_select "span.username", uppercase_user.display_name
  end

  def test_login_username_password_duplicate_downcase
    # When there's no exact match for case, and two possible users, it should fail
    user = create(:user)
    _uppercase_user = build(:user, :display_name => user.display_name.upcase).tap { |u| u.save(:validate => false) }

    try_password_login user.display_name.downcase, "test"

    assert_template "login"
    assert_select "span.username", false
  end

  # When there are no duplicate emails, any variation of cases should work
  def test_login_username_password
    user = create(:user)

    try_password_login user.display_name, "test"

    assert_template "changeset/history"
    assert_select "span.username", user.display_name
  end

  def test_login_username_password_upcase
    user = create(:user)

    try_password_login user.display_name.upcase, "test"

    assert_template "changeset/history"
    assert_select "span.username", user.display_name
  end

  def test_login_username_password_downcase
    user = create(:user)

    try_password_login user.display_name.downcase, "test"

    assert_template "changeset/history"
    assert_select "span.username", user.display_name
  end

  def test_login_username_password_pending
    user = create(:user, :pending)

    try_password_login user.display_name, "test"

    assert_template "confirm"
    assert_select "span.username", false
  end

  def test_login_username_password_pending_upcase
    user = create(:user, :pending)

    try_password_login user.display_name.upcase, "test"

    assert_template "confirm"
    assert_select "span.username", false
  end

  def test_login_username_password_pending_downcase
    user = create(:user, :pending)

    try_password_login user.display_name.downcase, "test"

    assert_template "confirm"
    assert_select "span.username", false
  end

  def test_login_username_password_suspended
    user = create(:user, :suspended)

    try_password_login user.display_name, "test"

    assert_template "login"
    assert_select "span.username", false
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_username_password_suspended_upcase
    user = create(:user, :suspended)

    try_password_login user.display_name.upcase, "test"

    assert_template "login"
    assert_select "span.username", false
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_username_password_suspended_downcase
    user = create(:user, :suspended)

    try_password_login user.display_name.downcase, "test"

    assert_template "login"
    assert_select "span.username", false
    assert_select "div.flash.error", /your account has been suspended/
  end

  def test_login_username_password_blocked
    user = create(:user)
    create(:user_block, :needs_view, :user => user)

    try_password_login user.display_name.upcase, "test"

    assert_template "user_blocks/show"
    assert_select "span.username", user.display_name
  end

  def test_login_username_password_blocked_upcase
    user = create(:user)
    create(:user_block, :needs_view, :user => user)

    try_password_login user.display_name, "test"

    assert_template "user_blocks/show"
    assert_select "span.username", user.display_name
  end

  def test_login_username_password_blocked_downcase
    user = create(:user)
    create(:user_block, :needs_view, :user => user)

    try_password_login user.display_name.downcase, "test"

    assert_template "user_blocks/show"
    assert_select "span.username", user.display_name
  end

  def test_login_email_password_remember_me
    user = create(:user)

    try_password_login user.email, "test", "yes"

    assert_template "changeset/history"
    assert_select "span.username", user.display_name
    assert session.key?(:_remember_for)
  end

  def test_login_username_password_remember_me
    user = create(:user)

    try_password_login user.display_name, "test", "yes"

    assert_template "changeset/history"
    assert_select "span.username", user.display_name
    assert session.key?(:_remember_for)
  end

  def test_login_openid_success
    user = create(:user, :auth_provider => "openid", :auth_uid => "http://example.com/john.doe")
    OmniAuth.config.add_mock(:openid, :uid => user.auth_uid)

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true, :referer => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    post "/login", :params => { :openid_url => "http://localhost:1123/john.doe", :referer => "/history" }
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
    assert_select "span.username", user.display_name
  end

  def test_login_openid_remember_me
    user = create(:user, :auth_provider => "openid", :auth_uid => "http://example.com/john.doe")
    OmniAuth.config.add_mock(:openid, :uid => user.auth_uid)

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true, :referer => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    post "/login", :params => { :openid_url => user.auth_uid, :remember_me_openid => true, :referer => "/history" }
    assert_response :redirect
    assert_redirected_to auth_path(:provider => "openid", :openid_url => user.auth_uid, :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "openid", :openid_url => user.auth_uid, :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", user.display_name
    assert session.key?(:_remember_for)
  end

  def test_login_openid_connection_failed
    user = create(:user, :auth_provider => "openid", :auth_uid => "http://example.com/john.doe")
    OmniAuth.config.mock_auth[:openid] = :connection_failed

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true, :referer => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    post "/login", :params => { :openid_url => user.auth_uid, :referer => "/history" }
    assert_response :redirect
    assert_redirected_to auth_path(:provider => "openid", :openid_url => user.auth_uid, :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "openid", :openid_url => user.auth_uid, :origin => "/login?referer=%2Fhistory", :referer => "/history")
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
    user = create(:user, :auth_provider => "openid", :auth_uid => "http://example.com/john.doe")
    OmniAuth.config.mock_auth[:openid] = :invalid_credentials

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true, :referer => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    post "/login", :params => { :openid_url => user.auth_uid, :referer => "/history" }
    assert_response :redirect
    assert_redirected_to auth_path(:provider => "openid", :openid_url => user.auth_uid, :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "openid", :openid_url => user.auth_uid, :origin => "/login?referer=%2Fhistory", :referer => "/history")
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

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :cookie_test => true, :referer => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    post "/login", :params => { :openid_url => "http://localhost:1123/fred.bloggs", :referer => "/history" }
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
    user = create(:user, :auth_provider => "google", :auth_uid => "1234567890")
    OmniAuth.config.add_mock(:google, :uid => user.auth_uid, :extra => {
                               :id_info => { "openid_id" => "http://localhost:1123/fred.bloggs" }
                             })

    get "/login", :params => { :referer => "/history" }
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
    assert_select "span.username", user.display_name
  end

  def test_login_google_connection_failed
    OmniAuth.config.mock_auth[:google] = :connection_failed

    get "/login", :params => { :referer => "/history" }
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

    get "/login", :params => { :referer => "/history" }
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

    get "/login", :params => { :referer => "/history" }
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
    user = create(:user, :auth_provider => "openid", :auth_uid => "http://example.com/john.doe")
    OmniAuth.config.add_mock(:google, :uid => "987654321", :extra => {
                               :id_info => { "openid_id" => user.auth_uid }
                             })

    get "/login", :params => { :referer => "/history" }
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
    assert_select "span.username", user.display_name

    u = User.find_by(:display_name => user.display_name)
    assert_equal "google", u.auth_provider
    assert_equal "987654321", u.auth_uid
  end

  def test_login_facebook_success
    user = create(:user, :auth_provider => "facebook", :auth_uid => "1234567890")
    OmniAuth.config.add_mock(:facebook, :uid => user.auth_uid)

    get "/login", :params => { :referer => "/history" }
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
    assert_select "span.username", user.display_name
  end

  def test_login_facebook_connection_failed
    OmniAuth.config.mock_auth[:facebook] = :connection_failed

    get "/login", :params => { :referer => "/history" }
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

    get "/login", :params => { :referer => "/history" }
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

    get "/login", :params => { :referer => "/history" }
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
    user = create(:user, :auth_provider => "windowslive", :auth_uid => "1234567890")
    OmniAuth.config.add_mock(:windowslive, :uid => user.auth_uid)

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "windowslive", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "windowslive")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", user.display_name
  end

  def test_login_windowslive_connection_failed
    OmniAuth.config.mock_auth[:windowslive] = :connection_failed

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "windowslive", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "windowslive")
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

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "windowslive", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "windowslive")
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

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "windowslive", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "windowslive")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user/new"
    assert_select "span.username", false
  end

  def test_login_github_success
    user = create(:user, :auth_provider => "github", :auth_uid => "1234567890")
    OmniAuth.config.add_mock(:github, :uid => user.auth_uid)

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "github", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "github")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", user.display_name
  end

  def test_login_github_connection_failed
    OmniAuth.config.mock_auth[:github] = :connection_failed

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "github", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "github")
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

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "github", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "github")
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

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "github", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "github")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "user/new"
    assert_select "span.username", false
  end

  def test_login_wikipedia_success
    user = create(:user, :auth_provider => "wikipedia", :auth_uid => "1234567890")
    OmniAuth.config.add_mock(:wikipedia, :uid => user.auth_uid)

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "wikipedia", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "wikipedia", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "changeset/history"
    assert_select "span.username", user.display_name
  end

  def test_login_wikipedia_connection_failed
    OmniAuth.config.mock_auth[:wikipedia] = :connection_failed

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "wikipedia", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "wikipedia", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_failure_path(:strategy => "wikipedia", :message => "connection_failed", :origin => "/login?referer=%2Fhistory")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", "Connection to authentication provider failed"
    assert_select "span.username", false
  end

  def test_login_wikipedia_invalid_credentials
    OmniAuth.config.mock_auth[:wikipedia] = :invalid_credentials

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "wikipedia", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "wikipedia", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    follow_redirect!
    assert_response :redirect
    assert_redirected_to auth_failure_path(:strategy => "wikipedia", :message => "invalid_credentials", :origin => "/login?referer=%2Fhistory")
    follow_redirect!
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "login"
    assert_select "div.flash.error", "Invalid authentication credentials"
    assert_select "span.username", false
  end

  def test_login_wikipedia_unknown
    OmniAuth.config.add_mock(:wikipedia, :uid => "987654321")

    get "/login", :params => { :referer => "/history" }
    assert_response :redirect
    assert_redirected_to "controller" => "user", "action" => "login", "cookie_test" => "true", "referer" => "/history"
    follow_redirect!
    assert_response :success
    assert_template "user/login"
    get auth_path(:provider => "wikipedia", :origin => "/login?referer=%2Fhistory", :referer => "/history")
    assert_response :redirect
    assert_redirected_to auth_success_path(:provider => "wikipedia", :origin => "/login?referer=%2Fhistory", :referer => "/history")
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

    post "/login", :params => { :username => username, :password => "wrong", :remember_me => remember_me, :referer => "/history" }
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

    post "/login", :params => { :username => username, :password => password, :remember_me => remember_me, :referer => "/history" }
    assert_response :redirect
    follow_redirect!
    assert_response :success
  end
end
