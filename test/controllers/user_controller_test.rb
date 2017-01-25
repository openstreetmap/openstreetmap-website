require "test_helper"

class UserControllerTest < ActionController::TestCase
  api_fixtures

  def setup
    stub_hostip_requests
  end

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/user/1", :method => :get },
      { :controller => "user", :action => "api_read", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/user/details", :method => :get },
      { :controller => "user", :action => "api_details" }
    )
    assert_routing(
      { :path => "/api/0.6/user/gpx_files", :method => :get },
      { :controller => "user", :action => "api_gpx_files" }
    )

    assert_routing(
      { :path => "/login", :method => :get },
      { :controller => "user", :action => "login" }
    )
    assert_routing(
      { :path => "/login", :method => :post },
      { :controller => "user", :action => "login" }
    )
    assert_recognizes(
      { :controller => "user", :action => "login", :format => "html" },
      { :path => "/login.html", :method => :get }
    )

    assert_routing(
      { :path => "/logout", :method => :get },
      { :controller => "user", :action => "logout" }
    )
    assert_routing(
      { :path => "/logout", :method => :post },
      { :controller => "user", :action => "logout" }
    )
    assert_recognizes(
      { :controller => "user", :action => "logout", :format => "html" },
      { :path => "/logout.html", :method => :get }
    )

    assert_routing(
      { :path => "/user/new", :method => :get },
      { :controller => "user", :action => "new" }
    )

    assert_routing(
      { :path => "/user/new", :method => :post },
      { :controller => "user", :action => "create" }
    )

    assert_routing(
      { :path => "/user/terms", :method => :get },
      { :controller => "user", :action => "terms" }
    )

    assert_routing(
      { :path => "/user/save", :method => :post },
      { :controller => "user", :action => "save" }
    )

    assert_routing(
      { :path => "/user/username/confirm", :method => :get },
      { :controller => "user", :action => "confirm", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/confirm", :method => :post },
      { :controller => "user", :action => "confirm", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/confirm/resend", :method => :get },
      { :controller => "user", :action => "confirm_resend", :display_name => "username" }
    )

    assert_routing(
      { :path => "/user/confirm", :method => :get },
      { :controller => "user", :action => "confirm" }
    )
    assert_routing(
      { :path => "/user/confirm", :method => :post },
      { :controller => "user", :action => "confirm" }
    )
    assert_routing(
      { :path => "/user/confirm-email", :method => :get },
      { :controller => "user", :action => "confirm_email" }
    )
    assert_routing(
      { :path => "/user/confirm-email", :method => :post },
      { :controller => "user", :action => "confirm_email" }
    )

    assert_routing(
      { :path => "/user/go_public", :method => :post },
      { :controller => "user", :action => "go_public" }
    )

    assert_routing(
      { :path => "/user/forgot-password", :method => :get },
      { :controller => "user", :action => "lost_password" }
    )
    assert_routing(
      { :path => "/user/forgot-password", :method => :post },
      { :controller => "user", :action => "lost_password" }
    )
    assert_routing(
      { :path => "/user/reset-password", :method => :get },
      { :controller => "user", :action => "reset_password" }
    )
    assert_routing(
      { :path => "/user/reset-password", :method => :post },
      { :controller => "user", :action => "reset_password" }
    )

    assert_routing(
      { :path => "/user/suspended", :method => :get },
      { :controller => "user", :action => "suspended" }
    )

    assert_routing(
      { :path => "/user/username", :method => :get },
      { :controller => "user", :action => "view", :display_name => "username" }
    )

    assert_routing(
      { :path => "/user/username/account", :method => :get },
      { :controller => "user", :action => "account", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/account", :method => :post },
      { :controller => "user", :action => "account", :display_name => "username" }
    )

    assert_routing(
      { :path => "/user/username/make_friend", :method => :get },
      { :controller => "user", :action => "make_friend", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/make_friend", :method => :post },
      { :controller => "user", :action => "make_friend", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/remove_friend", :method => :get },
      { :controller => "user", :action => "remove_friend", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/remove_friend", :method => :post },
      { :controller => "user", :action => "remove_friend", :display_name => "username" }
    )

    assert_routing(
      { :path => "/user/username/set_status", :method => :get },
      { :controller => "user", :action => "set_status", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/delete", :method => :get },
      { :controller => "user", :action => "delete", :display_name => "username" }
    )

    assert_routing(
      { :path => "/users", :method => :get },
      { :controller => "user", :action => "list" }
    )
    assert_routing(
      { :path => "/users", :method => :post },
      { :controller => "user", :action => "list" }
    )
    assert_routing(
      { :path => "/users/status", :method => :get },
      { :controller => "user", :action => "list", :status => "status" }
    )
    assert_routing(
      { :path => "/users/status", :method => :post },
      { :controller => "user", :action => "list", :status => "status" }
    )
  end

  # The user creation page loads
  def test_new_view
    get :new
    assert_response :redirect
    assert_redirected_to user_new_path(:cookie_test => "true")

    get :new, { :cookie_test => "true" }, { :cookie_test => true }
    assert_response :success

    assert_select "html", :count => 1 do
      assert_select "head", :count => 1 do
        assert_select "title", :text => /Sign Up/, :count => 1
      end
      assert_select "body", :count => 1 do
        assert_select "div#content", :count => 1 do
          assert_select "form[action='/user/new'][method='post']", :count => 1 do
            assert_select "input[id='user_email']", :count => 1
            assert_select "input[id='user_email_confirmation']", :count => 1
            assert_select "input[id='user_display_name']", :count => 1
            assert_select "input[id='user_pass_crypt'][type='password']", :count => 1
            assert_select "input[id='user_pass_crypt_confirmation'][type='password']", :count => 1
            assert_select "input[type='submit'][value='Sign Up']", :count => 1
          end
        end
      end
    end
  end

  def test_new_view_logged_in
    session[:user] = users(:normal_user).id

    get :new
    assert_response :redirect
    assert_redirected_to user_new_path(:cookie_test => "true")
    get :new, :cookie_test => "true"
    assert_response :redirect
    assert_redirected_to root_path

    get :new, :referer => "/test"
    assert_response :redirect
    assert_redirected_to user_new_path(:referer => "/test", :cookie_test => "true")
    get :new, :referer => "/test", :cookie_test => "true"
    assert_response :redirect
    assert_redirected_to "/test"
  end

  def test_new_success
    user = new_user

    assert_difference "User.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        post :save, {}, { :new_user => user }
      end
    end

    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first

    assert_equal register_email.to[0], user.email
    assert_match /#{@url}/, register_email.body.to_s

    # Check the page
    assert_redirected_to :action => "confirm", :display_name => user.display_name

    ActionMailer::Base.deliveries.clear
  end

  def test_new_duplicate_email
    user = new_user
    user.email = users(:public_user).email

    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        post :save, {}, { :new_user => user }
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.form-row > input.field_with_errors#user_email"
  end

  def test_new_duplicate_email_uppercase
    user = new_user
    user.email = users(:public_user).email.upcase

    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        post :save, {}, { :new_user => user }
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.form-row > input.field_with_errors#user_email"
  end

  def test_new_duplicate_name
    user = new_user
    user.display_name = users(:public_user).display_name

    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        post :save, {}, { :new_user => user }
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.form-row > input.field_with_errors#user_display_name"
  end

  def test_new_duplicate_name_uppercase
    user = new_user
    user.display_name = users(:public_user).display_name.upcase

    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        post :save, {}, { :new_user => user }
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.form-row > input.field_with_errors#user_display_name"
  end

  def test_save_referer_params
    user = new_user

    assert_difference "User.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        post :save, {}, { :new_user => user,
                          :referer => "/edit?editor=id#map=1/2/3" }
      end
    end

    assert_equal welcome_path(:editor => "id", :zoom => 1, :lat => 2, :lon => 3),
                 user.tokens.order("id DESC").first.referer

    ActionMailer::Base.deliveries.clear
  end

  def test_logout_without_referer
    get :logout
    assert_response :success
    assert_template :logout
    assert_select "input[name=referer][value=?]", ""

    session_id = assert_select("input[name=session]").first["value"]

    get :logout, :session => session_id
    assert_response :redirect
    assert_redirected_to root_path
  end

  def test_logout_with_referer
    get :logout, :referer => "/test"
    assert_response :success
    assert_template :logout
    assert_select "input[name=referer][value=?]", "/test"

    session_id = assert_select("input[name=session]").first["value"]

    get :logout, :session => session_id, :referer => "/test"
    assert_response :redirect
    assert_redirected_to "/test"
  end

  def test_logout_with_token
    token = users(:normal_user).tokens.create

    session[:token] = token.token

    get :logout
    assert_response :success
    assert_template :logout
    assert_select "input[name=referer][value=?]", ""
    assert_equal token.token, session[:token]
    assert_not_nil UserToken.where(:id => token.id).first

    session_id = assert_select("input[name=session]").first["value"]

    get :logout, :session => session_id
    assert_response :redirect
    assert_redirected_to root_path
    assert_nil session[:token]
    assert_nil UserToken.where(:id => token.id).first
  end

  def test_confirm_get
    user = users(:inactive_user)
    confirm_string = user.tokens.create.token

    @request.cookies["_osm_session"] = user.display_name
    get :confirm, :display_name => user.display_name, :confirm_string => confirm_string
    assert_response :success
    assert_template :confirm
  end

  def test_confirm_get_already_confirmed
    user = users(:normal_user)
    confirm_string = user.tokens.create.token

    @request.cookies["_osm_session"] = user.display_name
    get :confirm, :display_name => user.display_name, :confirm_string => confirm_string
    assert_response :redirect
    assert_redirected_to root_path
  end

  def test_confirm_success_no_token_no_referer
    user = users(:inactive_user)
    stub_gravatar_request(user.email)
    confirm_string = user.tokens.create.token

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, :display_name => user.display_name, :confirm_string => confirm_string
    assert_redirected_to login_path
    assert_match /Confirmed your account/, flash[:notice]
  end

  def test_confirm_success_good_token_no_referer
    user = users(:inactive_user)
    stub_gravatar_request(user.email)
    confirm_string = user.tokens.create.token
    token = user.tokens.create.token

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, { :display_name => user.display_name, :confirm_string => confirm_string }, { :token => token }
    assert_redirected_to welcome_path
  end

  def test_confirm_success_bad_token_no_referer
    user = users(:inactive_user)
    stub_gravatar_request(user.email)
    confirm_string = user.tokens.create.token
    token = users(:normal_user).tokens.create.token

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, { :display_name => user.display_name, :confirm_string => confirm_string }, { :token => token }
    assert_redirected_to login_path
    assert_match /Confirmed your account/, flash[:notice]
  end

  def test_confirm_success_no_token_with_referer
    user = users(:inactive_user)
    stub_gravatar_request(user.email)
    confirm_string = user.tokens.create(:referer => diary_new_path).token

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, :display_name => user.display_name, :confirm_string => confirm_string
    assert_redirected_to login_path(:referer => diary_new_path)
    assert_match /Confirmed your account/, flash[:notice]
  end

  def test_confirm_success_good_token_with_referer
    user = users(:inactive_user)
    stub_gravatar_request(user.email)
    confirm_string = user.tokens.create(:referer => diary_new_path).token
    token = user.tokens.create.token

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, { :display_name => user.display_name, :confirm_string => confirm_string }, { :token => token }
    assert_redirected_to diary_new_path
  end

  def test_confirm_success_bad_token_with_referer
    user = users(:inactive_user)
    stub_gravatar_request(user.email)
    confirm_string = user.tokens.create(:referer => diary_new_path).token
    token = users(:normal_user).tokens.create.token

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, { :display_name => user.display_name, :confirm_string => confirm_string }, { :token => token }
    assert_redirected_to login_path(:referer => diary_new_path)
    assert_match /Confirmed your account/, flash[:notice]
  end

  def test_confirm_expired_token
    user = users(:inactive_user)
    confirm_string = user.tokens.create(:expiry => 1.day.ago).token

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, :display_name => user.display_name, :confirm_string => confirm_string
    assert_redirected_to :action => "confirm"
    assert_match /confirmation code has expired/, flash[:error]
  end

  def test_confirm_already_confirmed
    user = users(:normal_user)
    confirm_string = user.tokens.create(:referer => diary_new_path).token

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, :display_name => user.display_name, :confirm_string => confirm_string
    assert_redirected_to :action => "login"
    assert_match /already been confirmed/, flash[:error]
  end

  def test_confirm_resend_success
    session[:token] = users(:inactive_user).tokens.create.token

    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      get :confirm_resend, :display_name => users(:inactive_user).display_name
    end

    assert_response :redirect
    assert_redirected_to login_path
    assert_match /sent a new confirmation/, flash[:notice]

    email = ActionMailer::Base.deliveries.last

    assert_equal users(:inactive_user).email, email.to.first

    ActionMailer::Base.deliveries.clear
  end

  def test_confirm_resend_no_token
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      get :confirm_resend, :display_name => users(:inactive_user).display_name
    end

    assert_response :redirect
    assert_redirected_to login_path
    assert_match "User Inactive User not found.", flash[:error]
  end

  def test_confirm_resend_unknown_user
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      get :confirm_resend, :display_name => "No Such User"
    end

    assert_response :redirect
    assert_redirected_to login_path
    assert_match "User No Such User not found.", flash[:error]
  end

  def test_confirm_email_get
    user = users(:normal_user)
    confirm_string = user.tokens.create.token

    get :confirm_email, :confirm_string => confirm_string
    assert_response :success
    assert_template :confirm_email
  end

  def test_confirm_email_success
    user = users(:second_public_user)
    stub_gravatar_request(user.new_email)
    confirm_string = user.tokens.create.token

    post :confirm_email, :confirm_string => confirm_string
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
    assert_match /Confirmed your change of email address/, flash[:notice]
  end

  def test_confirm_email_already_confirmed
    user = users(:normal_user)
    confirm_string = user.tokens.create.token

    post :confirm_email, :confirm_string => confirm_string
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
    assert_match /already been confirmed/, flash[:error]
  end

  def test_confirm_email_bad_token
    post :confirm_email, :confirm_string => "XXXXX"
    assert_response :success
    assert_template :confirm_email
    assert_match /confirmation code has expired or does not exist/, flash[:error]
  end

  ##
  # test if testing for a gravatar works
  # this happens when the email is actually changed
  # which is triggered by the confirmation mail
  def test_gravatar_auto_enable
    # switch to email that has a gravatar
    user = users(:first_gravatar_user)
    stub_gravatar_request(user.new_email, 200)
    confirm_string = user.tokens.create.token
    # precondition gravatar should be turned off
    assert !user.image_use_gravatar
    post :confirm_email, :confirm_string => confirm_string
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
    assert_match /Confirmed your change of email address/, flash[:notice]
    # gravatar use should now be enabled
    assert User.find(users(:first_gravatar_user).id).image_use_gravatar
  end

  def test_gravatar_auto_disable
    # switch to email without a gravatar
    user = users(:second_gravatar_user)
    stub_gravatar_request(user.new_email, 404)
    confirm_string = user.tokens.create.token
    # precondition gravatar should be turned on
    assert user.image_use_gravatar
    post :confirm_email, :confirm_string => confirm_string
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
    assert_match /Confirmed your change of email address/, flash[:notice]
    # gravatar use should now be disabled
    assert !User.find(users(:second_gravatar_user).id).image_use_gravatar
  end

  def test_terms_new_user
    get :terms, {}, { :new_user => User.new }
    assert_response :success
    assert_template :terms
  end

  def test_terms_seen
    user = users(:normal_user)

    session[:user] = user.id

    get :terms
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
  end

  def test_terms_not_seen_without_referer
    user = users(:terms_not_seen_user)

    session[:user] = user.id

    get :terms
    assert_response :success
    assert_template :terms

    post :save, :user => { :consider_pd => true }
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
    assert_equal "Thanks for accepting the new contributor terms!", flash[:notice]

    user.reload

    assert_equal true, user.consider_pd
    assert_not_nil user.terms_agreed
    assert_equal true, user.terms_seen
  end

  def test_terms_not_seen_with_referer
    user = users(:terms_not_seen_user)

    session[:user] = user.id

    get :terms, :referer => "/test"
    assert_response :success
    assert_template :terms

    post :save, :user => { :consider_pd => true }, :referer => "/test"
    assert_response :redirect
    assert_redirected_to "/test"
    assert_equal "Thanks for accepting the new contributor terms!", flash[:notice]

    user.reload

    assert_equal true, user.consider_pd
    assert_not_nil user.terms_agreed
    assert_equal true, user.terms_seen
  end

  def test_go_public
    post :go_public, {}, { :user => users(:normal_user) }
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => users(:normal_user).display_name
    assert_equal true, User.find(users(:normal_user).id).data_public
  end

  def test_lost_password
    # Test fetching the lost password page
    get :lost_password
    assert_response :success
    assert_template :lost_password
    assert_select "div#notice", false

    # Test resetting using the address as recorded for a user that has an
    # address which is duplicated in a different case by another user
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post :lost_password, :user => { :email => users(:normal_user).email }
    end
    assert_response :redirect
    assert_redirected_to :action => :login
    assert_match /^Sorry you lost it/, flash[:notice]
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal users(:normal_user).email, email.to.first
    ActionMailer::Base.deliveries.clear

    # Test resetting using an address that matches a different user
    # that has the same address in a different case
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post :lost_password, :user => { :email => users(:normal_user).email.upcase }
    end
    assert_response :redirect
    assert_redirected_to :action => :login
    assert_match /^Sorry you lost it/, flash[:notice]
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal users(:uppercase_user).email, email.to.first
    ActionMailer::Base.deliveries.clear

    # Test resetting using an address that is a case insensitive match
    # for more than one user but not an exact match for either
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post :lost_password, :user => { :email => users(:normal_user).email.titlecase }
    end
    assert_response :success
    assert_template :lost_password
    assert_select ".error", /^Could not find that email address/

    # Test resetting using the address as recorded for a user that has an
    # address which is case insensitively unique
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post :lost_password, :user => { :email => users(:public_user).email }
    end
    assert_response :redirect
    assert_redirected_to :action => :login
    assert_match /^Sorry you lost it/, flash[:notice]
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal users(:public_user).email, email.to.first
    ActionMailer::Base.deliveries.clear

    # Test resetting using an address that matches a user that has the
    # same (case insensitively unique) address in a different case
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post :lost_password, :user => { :email => users(:public_user).email.upcase }
    end
    assert_response :redirect
    assert_redirected_to :action => :login
    assert_match /^Sorry you lost it/, flash[:notice]
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal users(:public_user).email, email.to.first
    ActionMailer::Base.deliveries.clear
  end

  def test_reset_password
    # Test a request with no token
    get :reset_password
    assert_response :bad_request

    # Test a request with a bogus token
    get :reset_password, :token => "made_up_token"
    assert_response :redirect
    assert_redirected_to :action => :lost_password

    # Create a valid token for a user
    token = User.find(users(:inactive_user).id).tokens.create

    # Test a request with a valid token
    get :reset_password, :token => token.token
    assert_response :success
    assert_template :reset_password

    # Test setting a new password
    post :reset_password, :token => token.token, :user => { :pass_crypt => "new_password", :pass_crypt_confirmation => "new_password" }
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal users(:inactive_user).id, session[:user]
    user = User.find(users(:inactive_user).id)
    assert_equal "active", user.status
    assert_equal true, user.email_valid
    assert_equal user, User.authenticate(:username => "inactive@openstreetmap.org", :password => "new_password")
  end

  def test_account
    # Get a user to work with - note that this user deliberately
    # conflicts with uppercase_user in the email and display name
    # fields to test that we can change other fields without any
    # validation errors being reported
    user = users(:normal_user)

    # Make sure that you are redirected to the login page when
    # you are not logged in
    get :account, :display_name => user.display_name
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => "login", :referer => "/user/test/account"

    # Make sure that you are blocked when not logged in as the right user
    get :account, { :display_name => user.display_name }, { :user => users(:public_user).id }
    assert_response :forbidden

    # Make sure we get the page when we are logged in as the right user
    get :account, { :display_name => user.display_name }, { :user => user }
    assert_response :success
    assert_template :account

    # Updating the description should work
    user.description = "new description"
    post :account, { :display_name => user.display_name, :user => user.attributes }, { :user => user.id }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row > div#user_description_container > div#user_description_content > textarea#user_description", user.description

    # Changing to a invalid editor should fail
    user.preferred_editor = "unknown"
    post :account, { :display_name => user.display_name, :user => user.attributes }, { :user => user.id }
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.form-row > select#user_preferred_editor > option[selected]", false

    # Changing to a valid editor should work
    user.preferred_editor = "potlatch2"
    post :account, { :display_name => user.display_name, :user => user.attributes }, { :user => user.id }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row > select#user_preferred_editor > option[selected][value=?]", "potlatch2"

    # Changing to the default editor should work
    user.preferred_editor = "default"
    post :account, { :display_name => user.display_name, :user => user.attributes }, { :user => user.id }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row > select#user_preferred_editor > option[selected]", false

    # Changing to an uploaded image should work
    image = Rack::Test::UploadedFile.new("test/traces/1.gif", "image/gif")
    post :account, { :display_name => user.display_name, :image_action => "new", :user => user.attributes.merge(:image => image) }, { :user => user.id }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row.accountImage input[name=image_action][checked][value=?]", "keep"

    # Changing to a gravatar image should work
    post :account, { :display_name => user.display_name, :image_action => "gravatar", :user => user.attributes }, { :user => user.id }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row.accountImage input[name=image_action][checked][value=?]", "gravatar"

    # Removing the image should work
    post :account, { :display_name => user.display_name, :image_action => "delete", :user => user.attributes }, { :user => user.id }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row.accountImage input[name=image_action][checked]", false

    # Adding external authentication should redirect to the auth provider
    post :account, { :display_name => user.display_name, :user => user.attributes.merge(:auth_provider => "openid", :auth_uid => "gmail.com") }, { :user => user.id }
    assert_response :redirect
    assert_redirected_to auth_path(:provider => "openid", :openid_url => "https://www.google.com/accounts/o8/id", :origin => "/user/#{user.display_name}/account")

    # Changing name to one that exists should fail
    new_attributes = user.attributes.dup.merge(:display_name => users(:public_user).display_name)
    post :account, { :display_name => user.display_name, :user => new_attributes }, { :user => user.id }
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.form-row > input.field_with_errors#user_display_name"

    # Changing name to one that exists should fail, regardless of case
    new_attributes = user.attributes.dup.merge(:display_name => users(:public_user).display_name.upcase)
    post :account, { :display_name => user.display_name, :user => new_attributes }, { :user => user.id }
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.form-row > input.field_with_errors#user_display_name"

    # Changing name to one that doesn't exist should work
    new_attributes = user.attributes.dup.merge(:display_name => "new tester")
    post :account, { :display_name => user.display_name, :user => new_attributes }, { :user => user.id }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row > input#user_display_name[value=?]", "new tester"

    # Record the change of name
    user.display_name = "new tester"

    # Changing email to one that exists should fail
    user.new_email = users(:public_user).email
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post :account, { :display_name => user.display_name, :user => user.attributes }, { :user => user.id }
    end
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.form-row > input.field_with_errors#user_new_email"

    # Changing email to one that exists should fail, regardless of case
    user.new_email = users(:public_user).email.upcase
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post :account, { :display_name => user.display_name, :user => user.attributes }, { :user => user.id }
    end
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.form-row > input.field_with_errors#user_new_email"

    # Changing email to one that doesn't exist should work
    user.new_email = "new_tester@example.com"
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post :account, { :display_name => user.display_name, :user => user.attributes }, { :user => user.id }
    end
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row > input#user_new_email[value=?]", user.new_email
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal user.new_email, email.to.first
    ActionMailer::Base.deliveries.clear
  end

  # Check that the user account page will display and contains some relevant
  # information for the user
  def test_view
    # Test a non-existent user
    get :view, :display_name => "unknown"
    assert_response :not_found

    # Test a normal user
    get :view, :display_name => "test"
    assert_response :success
    assert_select "div#userinformation" do
      assert_select "a[href^='/user/test/history']", 1
      assert_select "a[href='/user/test/traces']", 1
      assert_select "a[href='/user/test/diary']", 1
      assert_select "a[href='/user/test/diary/comments']", 1
      assert_select "a[href='/user/test/account']", 0
      assert_select "a[href='/user/test/blocks']", 0
      assert_select "a[href='/user/test/blocks_by']", 0
      assert_select "a[href='/blocks/new/test']", 0
    end

    # Test a user who has been blocked
    create(:user_block, :user => users(:blocked_user))
    get :view, :display_name => "blocked"
    assert_response :success
    assert_select "div#userinformation" do
      assert_select "a[href^='/user/blocked/history']", 1
      assert_select "a[href='/user/blocked/traces']", 1
      assert_select "a[href='/user/blocked/diary']", 1
      assert_select "a[href='/user/blocked/diary/comments']", 1
      assert_select "a[href='/user/blocked/account']", 0
      assert_select "a[href='/user/blocked/blocks']", 1
      assert_select "a[href='/user/blocked/blocks_by']", 0
      assert_select "a[href='/blocks/new/blocked']", 0
    end

    # Test a moderator who has applied blocks
    create(:user_block, :creator => users(:moderator_user))
    get :view, :display_name => "moderator"
    assert_response :success
    assert_select "div#userinformation" do
      assert_select "a[href^='/user/moderator/history']", 1
      assert_select "a[href='/user/moderator/traces']", 1
      assert_select "a[href='/user/moderator/diary']", 1
      assert_select "a[href='/user/moderator/diary/comments']", 1
      assert_select "a[href='/user/moderator/account']", 0
      assert_select "a[href='/user/moderator/blocks']", 0
      assert_select "a[href='/user/moderator/blocks_by']", 1
      assert_select "a[href='/blocks/new/moderator']", 0
    end

    # Login as a normal user
    session[:user] = users(:normal_user).id

    # Test the normal user
    get :view, :display_name => "test"
    assert_response :success
    assert_select "div#userinformation" do
      assert_select "a[href^='/user/test/history']", 1
      assert_select "a[href='/traces/mine']", 1
      assert_select "a[href='/user/test/diary']", 1
      assert_select "a[href='/user/test/diary/comments']", 1
      assert_select "a[href='/user/test/account']", 1
      assert_select "a[href='/user/test/blocks']", 0
      assert_select "a[href='/user/test/blocks_by']", 0
      assert_select "a[href='/blocks/new/test']", 0
    end

    # Login as a moderator
    session[:user] = users(:moderator_user).id

    # Test the normal user
    get :view, :display_name => "test"
    assert_response :success
    assert_select "div#userinformation" do
      assert_select "a[href^='/user/test/history']", 1
      assert_select "a[href='/user/test/traces']", 1
      assert_select "a[href='/user/test/diary']", 1
      assert_select "a[href='/user/test/diary/comments']", 1
      assert_select "a[href='/user/test/account']", 0
      assert_select "a[href='/user/test/blocks']", 0
      assert_select "a[href='/user/test/blocks_by']", 0
      assert_select "a[href='/blocks/new/test']", 1
    end
  end

  def test_api_read
    # check that a visible user is returned properly
    get :api_read, :id => users(:normal_user).id
    assert_response :success
    assert_equal "text/xml", response.content_type

    # check the data that is returned
    assert_select "description", :count => 1, :text => "test"
    assert_select "contributor-terms", :count => 1 do
      assert_select "[agreed='true']"
    end
    assert_select "img", :count => 0
    assert_select "roles", :count => 1 do
      assert_select "role", :count => 0
    end
    assert_select "changesets", :count => 1 do
      assert_select "[count='0']"
    end
    assert_select "traces", :count => 1 do
      assert_select "[count='0']"
    end
    assert_select "blocks", :count => 1 do
      assert_select "received", :count => 1 do
        assert_select "[count='0'][active='0']"
      end
      assert_select "issued", :count => 0
    end

    # check that we aren't revealing private information
    assert_select "contributor-terms[pd]", false
    assert_select "home", false
    assert_select "languages", false
    assert_select "messages", false

    # check that a suspended user is not returned
    get :api_read, :id => users(:suspended_user).id
    assert_response :gone

    # check that a deleted user is not returned
    get :api_read, :id => users(:deleted_user).id
    assert_response :gone

    # check that a non-existent user is not returned
    get :api_read, :id => 0
    assert_response :not_found
  end

  def test_api_details
    create(:message, :read, :recipient => users(:normal_user))

    # check that nothing is returned when not logged in
    get :api_details
    assert_response :unauthorized

    # check that we get a response when logged in
    basic_authorization(users(:normal_user).email, "test")
    get :api_details
    assert_response :success
    assert_equal "text/xml", response.content_type

    # check the data that is returned
    assert_select "description", :count => 1, :text => "test"
    assert_select "contributor-terms", :count => 1 do
      assert_select "[agreed='true'][pd='false']"
    end
    assert_select "img", :count => 0
    assert_select "roles", :count => 1 do
      assert_select "role", :count => 0
    end
    assert_select "changesets", :count => 1 do
      assert_select "[count='0']", :count => 1
    end
    assert_select "traces", :count => 1 do
      assert_select "[count='0']", :count => 1
    end
    assert_select "blocks", :count => 1 do
      assert_select "received", :count => 1 do
        assert_select "[count='0'][active='0']"
      end
      assert_select "issued", :count => 0
    end
    assert_select "home", :count => 1 do
      assert_select "[lat='12.1'][lon='12.1'][zoom='3']"
    end
    assert_select "languages", :count => 1 do
      assert_select "lang", :count => 1, :text => "en"
    end
    assert_select "messages", :count => 1 do
      assert_select "received", :count => 1 do
        assert_select "[count='1'][unread='0']"
      end
      assert_select "sent", :count => 1 do
        assert_select "[count='1']"
      end
    end
  end

  def test_api_gpx_files
    # check that nothing is returned when not logged in
    get :api_gpx_files
    assert_response :unauthorized

    # check that we get a response when logged in
    basic_authorization(users(:normal_user).email, "test")
    get :api_gpx_files
    assert_response :success
    assert_equal "text/xml", response.content_type

    # check the data that is returned
    assert_select "gpx_file[id='1']", 1 do
      assert_select "tag", "London"
    end
    assert_select "gpx_file[id='4']", 1 do
      assert_select "tag", "Birmingham"
    end
  end

  def test_make_friend
    # Get users to work with
    user = users(:normal_user)
    friend = users(:second_public_user)

    # Check that the users aren't already friends
    assert_nil Friend.where(:user_id => user.id, :friend_user_id => friend.id).first

    # When not logged in a GET should ask us to login
    get :make_friend, :display_name => friend.display_name
    assert_redirected_to :controller => :user, :action => "login", :referer => make_friend_path(:display_name => friend.display_name)

    # When not logged in a POST should error
    post :make_friend, :display_name => friend.display_name
    assert_response :forbidden
    assert_nil Friend.where(:user_id => user.id, :friend_user_id => friend.id).first

    # When logged in a GET should get a confirmation page
    get :make_friend, { :display_name => friend.display_name }, { :user => user.id }
    assert_response :success
    assert_template :make_friend
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer']", 0
      assert_select "input[type='submit']", 1
    end
    assert_nil Friend.where(:user_id => user.id, :friend_user_id => friend.id).first

    # When logged in a POST should add the friendship
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post :make_friend, { :display_name => friend.display_name }, { :user => user.id }
    end
    assert_redirected_to user_path(:display_name => friend.display_name)
    assert_match /is now your friend/, flash[:notice]
    assert Friend.where(:user_id => user.id, :friend_user_id => friend.id).first
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal friend.email, email.to.first
    ActionMailer::Base.deliveries.clear

    # A second POST should report that the friendship already exists
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post :make_friend, { :display_name => friend.display_name }, { :user => user.id }
    end
    assert_redirected_to user_path(:display_name => friend.display_name)
    assert_match /You are already friends with/, flash[:warning]
    assert Friend.where(:user_id => user.id, :friend_user_id => friend.id).first
  end

  def test_make_friend_with_referer
    # Get users to work with
    user = users(:normal_user)
    friend = users(:second_public_user)

    # Check that the users aren't already friends
    assert_nil Friend.where(:user_id => user.id, :friend_user_id => friend.id).first

    # The GET should preserve any referer
    get :make_friend, { :display_name => friend.display_name, :referer => "/test" }, { :user => user.id }
    assert_response :success
    assert_template :make_friend
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer'][value='/test']", 1
      assert_select "input[type='submit']", 1
    end
    assert_nil Friend.where(:user_id => user.id, :friend_user_id => friend.id).first

    # When logged in a POST should add the friendship and refer us
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post :make_friend, { :display_name => friend.display_name, :referer => "/test" }, { :user => user.id }
    end
    assert_redirected_to "/test"
    assert_match /is now your friend/, flash[:notice]
    assert Friend.where(:user_id => user.id, :friend_user_id => friend.id).first
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal friend.email, email.to.first
    ActionMailer::Base.deliveries.clear
  end

  def test_make_friend_unkown_user
    # Should error when a bogus user is specified
    get :make_friend, { :display_name => "No Such User" }, { :user => users(:normal_user).id }
    assert_response :not_found
    assert_template :no_such_user
  end

  def test_remove_friend
    # Get users to work with
    user = users(:normal_user)
    friend = users(:public_user)
    create(:friend, :befriender => user, :befriendee => friend)

    # Check that the users are friends
    assert Friend.where(:user_id => user.id, :friend_user_id => friend.id).first

    # When not logged in a GET should ask us to login
    get :remove_friend, :display_name => friend.display_name
    assert_redirected_to :controller => :user, :action => "login", :referer => remove_friend_path(:display_name => friend.display_name)

    # When not logged in a POST should error
    post :remove_friend, :display_name => friend.display_name
    assert_response :forbidden
    assert Friend.where(:user_id => user.id, :friend_user_id => friend.id).first

    # When logged in a GET should get a confirmation page
    get :remove_friend, { :display_name => friend.display_name }, { :user => user.id }
    assert_response :success
    assert_template :remove_friend
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer']", 0
      assert_select "input[type='submit']", 1
    end
    assert Friend.where(:user_id => user.id, :friend_user_id => friend.id).first

    # When logged in a POST should remove the friendship
    post :remove_friend, { :display_name => friend.display_name }, { :user => user.id }
    assert_redirected_to user_path(:display_name => friend.display_name)
    assert_match /was removed from your friends/, flash[:notice]
    assert_nil Friend.where(:user_id => user.id, :friend_user_id => friend.id).first

    # A second POST should report that the friendship does not exist
    post :remove_friend, { :display_name => friend.display_name }, { :user => user.id }
    assert_redirected_to user_path(:display_name => friend.display_name)
    assert_match /is not one of your friends/, flash[:error]
    assert_nil Friend.where(:user_id => user.id, :friend_user_id => friend.id).first
  end

  def test_remove_friend_with_referer
    # Get users to work with
    user = users(:normal_user)
    friend = users(:public_user)
    create(:friend, :user_id => user.id, :friend_user_id => friend.id)

    # Check that the users are friends
    assert Friend.where(:user_id => user.id, :friend_user_id => friend.id).first

    # The GET should preserve any referer
    get :remove_friend, { :display_name => friend.display_name, :referer => "/test" }, { :user => user.id }
    assert_response :success
    assert_template :remove_friend
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer'][value='/test']", 1
      assert_select "input[type='submit']", 1
    end
    assert Friend.where(:user_id => user.id, :friend_user_id => friend.id).first

    # When logged in a POST should remove the friendship and refer
    post :remove_friend, { :display_name => friend.display_name, :referer => "/test" }, { :user => user.id }
    assert_redirected_to "/test"
    assert_match /was removed from your friends/, flash[:notice]
    assert_nil Friend.where(:user_id => user.id, :friend_user_id => friend.id).first
  end

  def test_remove_friend_unkown_user
    # Should error when a bogus user is specified
    get :remove_friend, { :display_name => "No Such User" }, { :user => users(:normal_user).id }
    assert_response :not_found
    assert_template :no_such_user
  end

  def test_set_status
    # Try without logging in
    get :set_status, :display_name => users(:normal_user).display_name, :status => "suspended"
    assert_response :redirect
    assert_redirected_to :action => :login, :referer => set_status_user_path(:status => "suspended")

    # Now try as a normal user
    get :set_status, { :display_name => users(:normal_user).display_name, :status => "suspended" }, { :user => users(:normal_user).id }
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => users(:normal_user).display_name

    # Finally try as an administrator
    get :set_status, { :display_name => users(:normal_user).display_name, :status => "suspended" }, { :user => users(:administrator_user).id }
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => users(:normal_user).display_name
    assert_equal "suspended", User.find(users(:normal_user).id).status
  end

  def test_delete
    # Try without logging in
    get :delete, :display_name => users(:normal_user).display_name, :status => "suspended"
    assert_response :redirect
    assert_redirected_to :action => :login, :referer => delete_user_path(:status => "suspended")

    # Now try as a normal user
    get :delete, { :display_name => users(:normal_user).display_name, :status => "suspended" }, { :user => users(:normal_user).id }
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => users(:normal_user).display_name

    # Finally try as an administrator
    get :delete, { :display_name => users(:normal_user).display_name, :status => "suspended" }, { :user => users(:administrator_user).id }
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => users(:normal_user).display_name

    # Check that the user was deleted properly
    user = User.find(users(:normal_user).id)
    assert_equal "user_1", user.display_name
    assert_equal "", user.description
    assert_nil user.home_lat
    assert_nil user.home_lon
    assert_equal false, user.image.file?
    assert_equal false, user.email_valid
    assert_nil user.new_email
    assert_nil user.auth_provider
    assert_nil user.auth_uid
    assert_equal "deleted", user.status
  end

  def test_list_get
    # Shouldn't work when not logged in
    get :list
    assert_response :redirect
    assert_redirected_to :action => :login, :referer => users_path

    session[:user] = users(:normal_user).id

    # Shouldn't work when logged in as a normal user
    get :list
    assert_response :redirect
    assert_redirected_to :action => :login, :referer => users_path

    session[:user] = users(:moderator_user).id

    # Shouldn't work when logged in as a moderator
    get :list
    assert_response :redirect
    assert_redirected_to :action => :login, :referer => users_path

    session[:user] = users(:administrator_user).id

    # Should work when logged in as an administrator
    get :list
    assert_response :success
    assert_template :list
    assert_select "table#user_list tr", :count => User.count + 1

    # Should be able to limit by status
    get :list, :status => "suspended"
    assert_response :success
    assert_template :list
    assert_select "table#user_list tr", :count => User.where(:status => "suspended").count + 1

    # Should be able to limit by IP address
    get :list, :ip => "1.2.3.4"
    assert_response :success
    assert_template :list
    assert_select "table#user_list tr", :count => User.where(:creation_ip => "1.2.3.4").count + 1
  end

  def test_list_get_paginated
    1.upto(100).each do |n|
      User.create(:display_name => "extra_#{n}",
                  :email => "extra#{n}@example.com",
                  :pass_crypt => "extraextra")
    end

    session[:user] = users(:administrator_user).id

    get :list
    assert_response :success
    assert_template :list
    assert_select "table#user_list tr", :count => 51

    get :list, :page => 2
    assert_response :success
    assert_template :list
    assert_select "table#user_list tr", :count => 51

    get :list, :page => 3
    assert_response :success
    assert_template :list
    assert_select "table#user_list tr", :count => 26
  end

  def test_list_post_confirm
    inactive_user = users(:inactive_user)
    suspended_user = users(:suspended_user)

    # Shouldn't work when not logged in
    assert_no_difference "User.active.count" do
      post :list, :confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 }
    end
    assert_response :redirect
    assert_redirected_to :action => :login, :referer => users_path(:confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 })
    assert_equal "pending", inactive_user.reload.status
    assert_equal "suspended", suspended_user.reload.status

    session[:user] = users(:normal_user).id

    # Shouldn't work when logged in as a normal user
    assert_no_difference "User.active.count" do
      post :list, :confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 }
    end
    assert_response :redirect
    assert_redirected_to :action => :login, :referer => users_path(:confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 })
    assert_equal "pending", inactive_user.reload.status
    assert_equal "suspended", suspended_user.reload.status

    session[:user] = users(:moderator_user).id

    # Shouldn't work when logged in as a moderator
    assert_no_difference "User.active.count" do
      post :list, :confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 }
    end
    assert_response :redirect
    assert_redirected_to :action => :login, :referer => users_path(:confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 })
    assert_equal "pending", inactive_user.reload.status
    assert_equal "suspended", suspended_user.reload.status

    session[:user] = users(:administrator_user).id

    # Should work when logged in as an administrator
    assert_difference "User.active.count", 2 do
      post :list, :confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 }
    end
    assert_response :redirect
    assert_redirected_to :action => :list
    assert_equal "confirmed", inactive_user.reload.status
    assert_equal "confirmed", suspended_user.reload.status
  end

  def test_list_post_hide
    normal_user = users(:normal_user)
    confirmed_user = users(:confirmed_user)

    # Shouldn't work when not logged in
    assert_no_difference "User.active.count" do
      post :list, :hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 }
    end
    assert_response :redirect
    assert_redirected_to :action => :login, :referer => users_path(:hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 })
    assert_equal "active", normal_user.reload.status
    assert_equal "confirmed", confirmed_user.reload.status

    session[:user] = users(:normal_user).id

    # Shouldn't work when logged in as a normal user
    assert_no_difference "User.active.count" do
      post :list, :hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 }
    end
    assert_response :redirect
    assert_redirected_to :action => :login, :referer => users_path(:hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 })
    assert_equal "active", normal_user.reload.status
    assert_equal "confirmed", confirmed_user.reload.status

    session[:user] = users(:moderator_user).id

    # Shouldn't work when logged in as a moderator
    assert_no_difference "User.active.count" do
      post :list, :hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 }
    end
    assert_response :redirect
    assert_redirected_to :action => :login, :referer => users_path(:hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 })
    assert_equal "active", normal_user.reload.status
    assert_equal "confirmed", confirmed_user.reload.status

    session[:user] = users(:administrator_user).id

    # Should work when logged in as an administrator
    assert_difference "User.active.count", -2 do
      post :list, :hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 }
    end
    assert_response :redirect
    assert_redirected_to :action => :list
    assert_equal "deleted", normal_user.reload.status
    assert_equal "deleted", confirmed_user.reload.status
  end

  private

  def new_user
    user = User.new
    user.status = "pending"
    user.display_name = "new_tester"
    user.email = "newtester@osm.org"
    user.email_confirmation = "newtester@osm.org"
    user.pass_crypt = "testtest"
    user.pass_crypt_confirmation = "testtest"
    user
  end
end
