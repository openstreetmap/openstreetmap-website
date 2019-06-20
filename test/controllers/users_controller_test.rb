require "test_helper"

class UsersControllerTest < ActionController::TestCase
  def setup
    stub_hostip_requests
  end

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/login", :method => :get },
      { :controller => "users", :action => "login" }
    )
    assert_routing(
      { :path => "/login", :method => :post },
      { :controller => "users", :action => "login" }
    )
    assert_recognizes(
      { :controller => "users", :action => "login", :format => "html" },
      { :path => "/login.html", :method => :get }
    )

    assert_routing(
      { :path => "/logout", :method => :get },
      { :controller => "users", :action => "logout" }
    )
    assert_routing(
      { :path => "/logout", :method => :post },
      { :controller => "users", :action => "logout" }
    )
    assert_recognizes(
      { :controller => "users", :action => "logout", :format => "html" },
      { :path => "/logout.html", :method => :get }
    )

    assert_routing(
      { :path => "/user/new", :method => :get },
      { :controller => "users", :action => "new" }
    )

    assert_routing(
      { :path => "/user/new", :method => :post },
      { :controller => "users", :action => "create" }
    )

    assert_routing(
      { :path => "/user/terms", :method => :get },
      { :controller => "users", :action => "terms" }
    )

    assert_routing(
      { :path => "/user/save", :method => :post },
      { :controller => "users", :action => "save" }
    )

    assert_routing(
      { :path => "/user/username/confirm", :method => :get },
      { :controller => "users", :action => "confirm", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/confirm", :method => :post },
      { :controller => "users", :action => "confirm", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/confirm/resend", :method => :get },
      { :controller => "users", :action => "confirm_resend", :display_name => "username" }
    )

    assert_routing(
      { :path => "/user/confirm", :method => :get },
      { :controller => "users", :action => "confirm" }
    )
    assert_routing(
      { :path => "/user/confirm", :method => :post },
      { :controller => "users", :action => "confirm" }
    )
    assert_routing(
      { :path => "/user/confirm-email", :method => :get },
      { :controller => "users", :action => "confirm_email" }
    )
    assert_routing(
      { :path => "/user/confirm-email", :method => :post },
      { :controller => "users", :action => "confirm_email" }
    )

    assert_routing(
      { :path => "/user/go_public", :method => :post },
      { :controller => "users", :action => "go_public" }
    )

    assert_routing(
      { :path => "/user/forgot-password", :method => :get },
      { :controller => "users", :action => "lost_password" }
    )
    assert_routing(
      { :path => "/user/forgot-password", :method => :post },
      { :controller => "users", :action => "lost_password" }
    )
    assert_routing(
      { :path => "/user/reset-password", :method => :get },
      { :controller => "users", :action => "reset_password" }
    )
    assert_routing(
      { :path => "/user/reset-password", :method => :post },
      { :controller => "users", :action => "reset_password" }
    )

    assert_routing(
      { :path => "/user/suspended", :method => :get },
      { :controller => "users", :action => "suspended" }
    )

    assert_routing(
      { :path => "/user/username", :method => :get },
      { :controller => "users", :action => "show", :display_name => "username" }
    )

    assert_routing(
      { :path => "/user/username/account", :method => :get },
      { :controller => "users", :action => "account", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/account", :method => :post },
      { :controller => "users", :action => "account", :display_name => "username" }
    )

    assert_routing(
      { :path => "/user/username/make_friend", :method => :get },
      { :controller => "users", :action => "make_friend", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/make_friend", :method => :post },
      { :controller => "users", :action => "make_friend", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/remove_friend", :method => :get },
      { :controller => "users", :action => "remove_friend", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/remove_friend", :method => :post },
      { :controller => "users", :action => "remove_friend", :display_name => "username" }
    )

    assert_routing(
      { :path => "/user/username/set_status", :method => :get },
      { :controller => "users", :action => "set_status", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/delete", :method => :get },
      { :controller => "users", :action => "delete", :display_name => "username" }
    )

    assert_routing(
      { :path => "/users", :method => :get },
      { :controller => "users", :action => "index" }
    )
    assert_routing(
      { :path => "/users", :method => :post },
      { :controller => "users", :action => "index" }
    )
    assert_routing(
      { :path => "/users/status", :method => :get },
      { :controller => "users", :action => "index", :status => "status" }
    )
    assert_routing(
      { :path => "/users/status", :method => :post },
      { :controller => "users", :action => "index", :status => "status" }
    )
  end

  # The user creation page loads
  def test_new_view
    get :new
    assert_response :redirect
    assert_redirected_to user_new_path(:cookie_test => "true")

    get :new, :params => { :cookie_test => "true" }, :session => { :cookie_test => true }
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
    session[:user] = create(:user).id

    get :new
    assert_response :redirect
    assert_redirected_to user_new_path(:cookie_test => "true")
    get :new, :params => { :cookie_test => "true" }
    assert_response :redirect
    assert_redirected_to root_path

    get :new, :params => { :referer => "/test" }
    assert_response :redirect
    assert_redirected_to user_new_path(:referer => "/test", :cookie_test => "true")
    get :new, :params => { :referer => "/test", :cookie_test => "true" }
    assert_response :redirect
    assert_redirected_to "/test"
  end

  def test_new_success
    user = build(:user, :pending)

    assert_difference "User.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        perform_enqueued_jobs do
          post :save, :session => { :new_user => user }, :params => { :read_ct => 1, :read_tou => 1 }
        end
      end
    end

    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first

    assert_equal register_email.to[0], user.email
    assert_match(/#{@url}/, register_email.body.to_s)

    # Check the page
    assert_redirected_to :action => "confirm", :display_name => user.display_name

    ActionMailer::Base.deliveries.clear
  end

  def test_new_duplicate_email
    user = build(:user, :pending)
    user.email = create(:user).email

    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post :save, :session => { :new_user => user }, :params => { :read_ct => 1, :read_tou => 1 }
        end
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.form-row > input.field_with_errors#user_email"
  end

  def test_new_duplicate_email_uppercase
    user = build(:user, :pending)
    user.email = create(:user).email.upcase

    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post :save, :session => { :new_user => user }, :params => { :read_ct => 1, :read_tou => 1 }
        end
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.form-row > input.field_with_errors#user_email"
  end

  def test_new_duplicate_name
    user = build(:user, :pending)
    user.display_name = create(:user).display_name

    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post :save, :session => { :new_user => user }, :params => { :read_ct => 1, :read_tou => 1 }
        end
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.form-row > input.field_with_errors#user_display_name"
  end

  def test_new_duplicate_name_uppercase
    user = build(:user, :pending)
    user.display_name = create(:user).display_name.upcase

    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post :save, :session => { :new_user => user }, :params => { :read_ct => 1, :read_tou => 1 }
        end
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.form-row > input.field_with_errors#user_display_name"
  end

  def test_new_blocked_domain
    user = build(:user, :pending, :email => "user@example.net")
    create(:acl, :domain => "example.net", :k => "no_account_creation")

    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post :save, :session => { :new_user => user }, :params => { :read_ct => 1, :read_tou => 1 }
        end
      end
    end

    assert_response :success
    assert_template "blocked"
  end

  def test_save_referer_params
    user = build(:user, :pending)

    assert_difference "User.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        perform_enqueued_jobs do
          post :save, :session => { :new_user => user,
                                    :referer => "/edit?editor=id#map=1/2/3" },
                      :params => { :read_ct => 1, :read_tou => 1 }
        end
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

    get :logout, :params => { :session => session_id }
    assert_response :redirect
    assert_redirected_to root_path
  end

  def test_logout_with_referer
    get :logout, :params => { :referer => "/test" }
    assert_response :success
    assert_template :logout
    assert_select "input[name=referer][value=?]", "/test"

    session_id = assert_select("input[name=session]").first["value"]

    get :logout, :params => { :session => session_id, :referer => "/test" }
    assert_response :redirect
    assert_redirected_to "/test"
  end

  def test_logout_with_token
    token = create(:user).tokens.create

    session[:token] = token.token

    get :logout
    assert_response :success
    assert_template :logout
    assert_select "input[name=referer][value=?]", ""
    assert_equal token.token, session[:token]
    assert_not_nil UserToken.where(:id => token.id).first

    session_id = assert_select("input[name=session]").first["value"]

    get :logout, :params => { :session => session_id }
    assert_response :redirect
    assert_redirected_to root_path
    assert_nil session[:token]
    assert_nil UserToken.where(:id => token.id).first
  end

  def test_confirm_get
    user = create(:user, :pending)
    confirm_string = user.tokens.create.token

    @request.cookies["_osm_session"] = user.display_name
    get :confirm, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_response :success
    assert_template :confirm
  end

  def test_confirm_get_already_confirmed
    user = create(:user)
    confirm_string = user.tokens.create.token

    @request.cookies["_osm_session"] = user.display_name
    get :confirm, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_response :redirect
    assert_redirected_to root_path
  end

  def test_confirm_success_no_token_no_referer
    user = create(:user, :pending)
    stub_gravatar_request(user.email)
    confirm_string = user.tokens.create.token

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_redirected_to login_path
    assert_match(/Confirmed your account/, flash[:notice])
  end

  def test_confirm_success_good_token_no_referer
    user = create(:user, :pending)
    stub_gravatar_request(user.email)
    confirm_string = user.tokens.create.token
    token = user.tokens.create.token

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, :params => { :display_name => user.display_name, :confirm_string => confirm_string }, :session => { :token => token }
    assert_redirected_to welcome_path
  end

  def test_confirm_success_bad_token_no_referer
    user = create(:user, :pending)
    stub_gravatar_request(user.email)
    confirm_string = user.tokens.create.token
    token = create(:user).tokens.create.token

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, :params => { :display_name => user.display_name, :confirm_string => confirm_string }, :session => { :token => token }
    assert_redirected_to login_path
    assert_match(/Confirmed your account/, flash[:notice])
  end

  def test_confirm_success_no_token_with_referer
    user = create(:user, :pending)
    stub_gravatar_request(user.email)
    confirm_string = user.tokens.create(:referer => new_diary_entry_path).token

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_redirected_to login_path(:referer => new_diary_entry_path)
    assert_match(/Confirmed your account/, flash[:notice])
  end

  def test_confirm_success_good_token_with_referer
    user = create(:user, :pending)
    stub_gravatar_request(user.email)
    confirm_string = user.tokens.create(:referer => new_diary_entry_path).token
    token = user.tokens.create.token

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, :params => { :display_name => user.display_name, :confirm_string => confirm_string }, :session => { :token => token }
    assert_redirected_to new_diary_entry_path
  end

  def test_confirm_success_bad_token_with_referer
    user = create(:user, :pending)
    stub_gravatar_request(user.email)
    confirm_string = user.tokens.create(:referer => new_diary_entry_path).token
    token = create(:user).tokens.create.token

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, :params => { :display_name => user.display_name, :confirm_string => confirm_string }, :session => { :token => token }
    assert_redirected_to login_path(:referer => new_diary_entry_path)
    assert_match(/Confirmed your account/, flash[:notice])
  end

  def test_confirm_expired_token
    user = create(:user, :pending)
    confirm_string = user.tokens.create(:expiry => 1.day.ago).token

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_redirected_to :action => "confirm"
    assert_match(/confirmation code has expired/, flash[:error])
  end

  def test_confirm_already_confirmed
    user = create(:user)
    confirm_string = user.tokens.create(:referer => new_diary_entry_path).token

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_redirected_to :action => "login"
    assert_match(/already been confirmed/, flash[:error])
  end

  def test_confirm_resend_success
    user = create(:user, :pending)
    session[:token] = user.tokens.create.token

    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        get :confirm_resend, :params => { :display_name => user.display_name }
      end
    end

    assert_response :redirect
    assert_redirected_to login_path
    assert_match(/sent a new confirmation/, flash[:notice])

    email = ActionMailer::Base.deliveries.last

    assert_equal user.email, email.to.first

    ActionMailer::Base.deliveries.clear
  end

  def test_confirm_resend_no_token
    user = create(:user, :pending)
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        get :confirm_resend, :params => { :display_name => user.display_name }
      end
    end

    assert_response :redirect
    assert_redirected_to login_path
    assert_match "User #{user.display_name} not found.", flash[:error]
  end

  def test_confirm_resend_unknown_user
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        get :confirm_resend, :params => { :display_name => "No Such User" }
      end
    end

    assert_response :redirect
    assert_redirected_to login_path
    assert_match "User No Such User not found.", flash[:error]
  end

  def test_confirm_email_get
    user = create(:user)
    confirm_string = user.tokens.create.token

    get :confirm_email, :params => { :confirm_string => confirm_string }
    assert_response :success
    assert_template :confirm_email
  end

  def test_confirm_email_success
    user = create(:user, :new_email => "test-new@example.com")
    stub_gravatar_request(user.new_email)
    confirm_string = user.tokens.create.token

    post :confirm_email, :params => { :confirm_string => confirm_string }
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
    assert_match(/Confirmed your change of email address/, flash[:notice])
  end

  def test_confirm_email_already_confirmed
    user = create(:user)
    confirm_string = user.tokens.create.token

    post :confirm_email, :params => { :confirm_string => confirm_string }
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
    assert_match(/already been confirmed/, flash[:error])
  end

  def test_confirm_email_bad_token
    post :confirm_email, :params => { :confirm_string => "XXXXX" }
    assert_response :success
    assert_template :confirm_email
    assert_match(/confirmation code has expired or does not exist/, flash[:error])
  end

  ##
  # test if testing for a gravatar works
  # this happens when the email is actually changed
  # which is triggered by the confirmation mail
  def test_gravatar_auto_enable
    # switch to email that has a gravatar
    user = create(:user, :new_email => "test-new@example.com")
    stub_gravatar_request(user.new_email, 200)
    confirm_string = user.tokens.create.token
    # precondition gravatar should be turned off
    assert_not user.image_use_gravatar
    post :confirm_email, :params => { :confirm_string => confirm_string }
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
    assert_match(/Confirmed your change of email address/, flash[:notice])
    # gravatar use should now be enabled
    assert User.find(user.id).image_use_gravatar
  end

  def test_gravatar_auto_disable
    # switch to email without a gravatar
    user = create(:user, :new_email => "test-new@example.com", :image_use_gravatar => true)
    stub_gravatar_request(user.new_email, 404)
    confirm_string = user.tokens.create.token
    # precondition gravatar should be turned on
    assert user.image_use_gravatar
    post :confirm_email, :params => { :confirm_string => confirm_string }
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
    assert_match(/Confirmed your change of email address/, flash[:notice])
    # gravatar use should now be disabled
    assert_not User.find(user.id).image_use_gravatar
  end

  def test_terms_new_user
    get :terms, :session => { :new_user => User.new }
    assert_response :success
    assert_template :terms
  end

  def test_terms_agreed
    user = create(:user, :terms_seen => true, :terms_agreed => Date.yesterday)

    session[:user] = user.id

    get :terms
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
  end

  def test_terms_not_seen_without_referer
    user = create(:user, :terms_seen => false, :terms_agreed => nil)

    session[:user] = user.id

    get :terms
    assert_response :success
    assert_template :terms

    post :save, :params => { :user => { :consider_pd => true }, :read_ct => 1, :read_tou => 1 }
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
    assert_equal "Thanks for accepting the new contributor terms!", flash[:notice]

    user.reload

    assert_equal true, user.consider_pd
    assert_not_nil user.terms_agreed
    assert_equal true, user.terms_seen
  end

  def test_terms_not_seen_with_referer
    user = create(:user, :terms_seen => false, :terms_agreed => nil)

    session[:user] = user.id

    get :terms, :params => { :referer => "/test" }
    assert_response :success
    assert_template :terms

    post :save, :params => { :user => { :consider_pd => true }, :referer => "/test", :read_ct => 1, :read_tou => 1 }
    assert_response :redirect
    assert_redirected_to "/test"
    assert_equal "Thanks for accepting the new contributor terms!", flash[:notice]

    user.reload

    assert_equal true, user.consider_pd
    assert_not_nil user.terms_agreed
    assert_equal true, user.terms_seen
  end

  # Check that if you haven't seen the terms, and make a request that requires authentication,
  # that your request is redirected to view the terms
  def test_terms_not_seen_redirection
    user = create(:user, :terms_seen => false, :terms_agreed => nil)
    session[:user] = user.id

    get :account, :params => { :display_name => user.display_name }
    assert_response :redirect
    assert_redirected_to :action => :terms, :referer => "/user/#{ERB::Util.u(user.display_name)}/account"
  end

  def test_go_public
    user = create(:user, :data_public => false)
    post :go_public, :session => { :user => user }
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
    assert_equal true, User.find(user.id).data_public
  end

  def test_lost_password
    # Test fetching the lost password page
    get :lost_password
    assert_response :success
    assert_template :lost_password
    assert_select "div#notice", false

    # Test resetting using the address as recorded for a user that has an
    # address which is duplicated in a different case by another user
    user = create(:user)
    uppercase_user = build(:user, :email => user.email.upcase).tap { |u| u.save(:validate => false) }

    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post :lost_password, :params => { :user => { :email => user.email } }
      end
    end
    assert_response :redirect
    assert_redirected_to :action => :login
    assert_match(/^Sorry you lost it/, flash[:notice])
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal user.email, email.to.first
    ActionMailer::Base.deliveries.clear

    # Test resetting using an address that matches a different user
    # that has the same address in a different case
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post :lost_password, :params => { :user => { :email => user.email.upcase } }
      end
    end
    assert_response :redirect
    assert_redirected_to :action => :login
    assert_match(/^Sorry you lost it/, flash[:notice])
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal uppercase_user.email, email.to.first
    ActionMailer::Base.deliveries.clear

    # Test resetting using an address that is a case insensitive match
    # for more than one user but not an exact match for either
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        post :lost_password, :params => { :user => { :email => user.email.titlecase } }
      end
    end
    assert_response :success
    assert_template :lost_password
    assert_select ".error", /^Could not find that email address/

    # Test resetting using the address as recorded for a user that has an
    # address which is case insensitively unique
    third_user = create(:user)
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post :lost_password, :params => { :user => { :email => third_user.email } }
      end
    end
    assert_response :redirect
    assert_redirected_to :action => :login
    assert_match(/^Sorry you lost it/, flash[:notice])
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal third_user.email, email.to.first
    ActionMailer::Base.deliveries.clear

    # Test resetting using an address that matches a user that has the
    # same (case insensitively unique) address in a different case
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post :lost_password, :params => { :user => { :email => third_user.email.upcase } }
      end
    end
    assert_response :redirect
    assert_redirected_to :action => :login
    assert_match(/^Sorry you lost it/, flash[:notice])
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal third_user.email, email.to.first
    ActionMailer::Base.deliveries.clear
  end

  def test_reset_password
    user = create(:user, :pending)
    # Test a request with no token
    get :reset_password
    assert_response :bad_request

    # Test a request with a bogus token
    get :reset_password, :params => { :token => "made_up_token" }
    assert_response :redirect
    assert_redirected_to :action => :lost_password

    # Create a valid token for a user
    token = user.tokens.create

    # Test a request with a valid token
    get :reset_password, :params => { :token => token.token }
    assert_response :success
    assert_template :reset_password

    # Test that errors are reported for erroneous submissions
    post :reset_password, :params => { :token => token.token, :user => { :pass_crypt => "new_password", :pass_crypt_confirmation => "different_password" } }
    assert_response :success
    assert_template :reset_password
    assert_select "div#errorExplanation"

    # Test setting a new password
    post :reset_password, :params => { :token => token.token, :user => { :pass_crypt => "new_password", :pass_crypt_confirmation => "new_password" } }
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal user.id, session[:user]
    user.reload
    assert_equal "active", user.status
    assert_equal true, user.email_valid
    assert_equal user, User.authenticate(:username => user.email, :password => "new_password")
  end

  def test_account
    # Get a user to work with - note that this user deliberately
    # conflicts with uppercase_user in the email and display name
    # fields to test that we can change other fields without any
    # validation errors being reported
    user = create(:user, :languages => [])
    _uppercase_user = build(:user, :email => user.email.upcase, :display_name => user.display_name.upcase).tap { |u| u.save(:validate => false) }

    # Make sure that you are redirected to the login page when
    # you are not logged in
    get :account, :params => { :display_name => user.display_name }
    assert_response :redirect
    assert_redirected_to :action => "login", :referer => "/user/#{ERB::Util.u(user.display_name)}/account"

    # Make sure that you are blocked when not logged in as the right user
    get :account, :params => { :display_name => user.display_name }, :session => { :user => create(:user) }
    assert_response :forbidden

    # Make sure we get the page when we are logged in as the right user
    get :account, :params => { :display_name => user.display_name }, :session => { :user => user }
    assert_response :success
    assert_template :account
    assert_select "form#accountForm" do |form|
      assert_equal "post", form.attr("method").to_s
      assert_select "input[name='_method']", false
      assert_equal "/user/#{ERB::Util.u(user.display_name)}/account", form.attr("action").to_s
    end

    # Updating the description should work
    user.description = "new description"
    user.preferred_editor = "default"
    post :account, :params => { :display_name => user.display_name, :user => user.attributes }, :session => { :user => user }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row > div#user_description_container > div#user_description_content > textarea#user_description", user.description

    # Changing to a invalid editor should fail
    user.preferred_editor = "unknown"
    post :account, :params => { :display_name => user.display_name, :user => user.attributes }, :session => { :user => user }
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.form-row > select#user_preferred_editor > option[selected]", false

    # Changing to a valid editor should work
    user.preferred_editor = "potlatch2"
    post :account, :params => { :display_name => user.display_name, :user => user.attributes }, :session => { :user => user }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row > select#user_preferred_editor > option[selected][value=?]", "potlatch2"

    # Changing to the default editor should work
    user.preferred_editor = "default"
    post :account, :params => { :display_name => user.display_name, :user => user.attributes }, :session => { :user => user }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row > select#user_preferred_editor > option[selected]", false

    # Changing to an uploaded image should work
    image = Rack::Test::UploadedFile.new("test/gpx/fixtures/a.gif", "image/gif")
    post :account, :params => { :display_name => user.display_name, :image_action => "new", :user => user.attributes.merge(:image => image) }, :session => { :user => user }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row.accountImage input[name=image_action][checked][value=?]", "keep"

    # Changing to a gravatar image should work
    post :account, :params => { :display_name => user.display_name, :image_action => "gravatar", :user => user.attributes }, :session => { :user => user }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row.accountImage input[name=image_action][checked][value=?]", "gravatar"

    # Removing the image should work
    post :account, :params => { :display_name => user.display_name, :image_action => "delete", :user => user.attributes }, :session => { :user => user }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row.accountImage input[name=image_action][checked]", false

    # Adding external authentication should redirect to the auth provider
    post :account, :params => { :display_name => user.display_name, :user => user.attributes.merge(:auth_provider => "openid", :auth_uid => "gmail.com") }, :session => { :user => user }
    assert_response :redirect
    assert_redirected_to auth_path(:provider => "openid", :openid_url => "https://www.google.com/accounts/o8/id", :origin => "/user/#{ERB::Util.u(user.display_name)}/account")

    # Changing name to one that exists should fail
    new_attributes = user.attributes.dup.merge(:display_name => create(:user).display_name)
    post :account, :params => { :display_name => user.display_name, :user => new_attributes }, :session => { :user => user }
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.form-row > input.field_with_errors#user_display_name"

    # Changing name to one that exists should fail, regardless of case
    new_attributes = user.attributes.dup.merge(:display_name => create(:user).display_name.upcase)
    post :account, :params => { :display_name => user.display_name, :user => new_attributes }, :session => { :user => user }
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.form-row > input.field_with_errors#user_display_name"

    # Changing name to one that doesn't exist should work
    new_attributes = user.attributes.dup.merge(:display_name => "new tester")
    post :account, :params => { :display_name => user.display_name, :user => new_attributes }, :session => { :user => user }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row > input#user_display_name[value=?]", "new tester"

    # Record the change of name
    user.display_name = "new tester"

    # Changing email to one that exists should fail
    user.new_email = create(:user).email
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        post :account, :params => { :display_name => user.display_name, :user => user.attributes }, :session => { :user => user }
      end
    end
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.form-row > input.field_with_errors#user_new_email"

    # Changing email to one that exists should fail, regardless of case
    user.new_email = create(:user).email.upcase
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        post :account, :params => { :display_name => user.display_name, :user => user.attributes }, :session => { :user => user }
      end
    end
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.form-row > input.field_with_errors#user_new_email"

    # Changing email to one that doesn't exist should work
    user.new_email = "new_tester@example.com"
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post :account, :params => { :display_name => user.display_name, :user => user.attributes }, :session => { :user => user }
      end
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
  def test_show
    # Test a non-existent user
    get :show, :params => { :display_name => "unknown" }
    assert_response :not_found

    # Test a normal user
    user = create(:user, :home_lon => 1.1, :home_lat => 1.1)
    friend_user = create(:user, :home_lon => 1.2, :home_lat => 1.2)
    create(:friendship, :befriender => user, :befriendee => friend_user)
    create(:changeset, :user => friend_user)

    get :show, :params => { :display_name => user.display_name }
    assert_response :success
    assert_select "div#userinformation" do
      assert_select "a[href^='/user/#{ERB::Util.u(user.display_name)}/history']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/traces']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/diary']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/diary/comments']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/account']", 0
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/blocks']", 0
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/blocks_by']", 0
      assert_select "a[href='/blocks/new/#{ERB::Util.u(user.display_name)}']", 0
    end

    # Friends shouldn't be visible as we're not logged in
    assert_select "div#friends-container", :count => 0

    # Test a user who has been blocked
    blocked_user = create(:user)
    create(:user_block, :user => blocked_user)
    get :show, :params => { :display_name => blocked_user.display_name }
    assert_response :success
    assert_select "div#userinformation" do
      assert_select "a[href^='/user/#{ERB::Util.u(blocked_user.display_name)}/history']", 1
      assert_select "a[href='/user/#{ERB::Util.u(blocked_user.display_name)}/traces']", 1
      assert_select "a[href='/user/#{ERB::Util.u(blocked_user.display_name)}/diary']", 1
      assert_select "a[href='/user/#{ERB::Util.u(blocked_user.display_name)}/diary/comments']", 1
      assert_select "a[href='/user/#{ERB::Util.u(blocked_user.display_name)}/account']", 0
      assert_select "a[href='/user/#{ERB::Util.u(blocked_user.display_name)}/blocks']", 1
      assert_select "a[href='/user/#{ERB::Util.u(blocked_user.display_name)}/blocks_by']", 0
      assert_select "a[href='/blocks/new/#{ERB::Util.u(blocked_user.display_name)}']", 0
    end

    # Test a moderator who has applied blocks
    moderator_user = create(:moderator_user)
    create(:user_block, :creator => moderator_user)
    get :show, :params => { :display_name => moderator_user.display_name }
    assert_response :success
    assert_select "div#userinformation" do
      assert_select "a[href^='/user/#{ERB::Util.u(moderator_user.display_name)}/history']", 1
      assert_select "a[href='/user/#{ERB::Util.u(moderator_user.display_name)}/traces']", 1
      assert_select "a[href='/user/#{ERB::Util.u(moderator_user.display_name)}/diary']", 1
      assert_select "a[href='/user/#{ERB::Util.u(moderator_user.display_name)}/diary/comments']", 1
      assert_select "a[href='/user/#{ERB::Util.u(moderator_user.display_name)}/account']", 0
      assert_select "a[href='/user/#{ERB::Util.u(moderator_user.display_name)}/blocks']", 0
      assert_select "a[href='/user/#{ERB::Util.u(moderator_user.display_name)}/blocks_by']", 1
      assert_select "a[href='/blocks/new/#{ERB::Util.u(moderator_user.display_name)}']", 0
    end

    # Login as a normal user
    session[:user] = user.id

    # Test the normal user
    get :show, :params => { :display_name => user.display_name }
    assert_response :success
    assert_select "div#userinformation" do
      assert_select "a[href^='/user/#{ERB::Util.u(user.display_name)}/history']", 1
      assert_select "a[href='/traces/mine']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/diary']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/diary/comments']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/account']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/blocks']", 0
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/blocks_by']", 0
      assert_select "a[href='/blocks/new/#{ERB::Util.u(user.display_name)}']", 0
    end

    # Friends should be visible as we're now logged in
    assert_select "div#friends-container" do
      assert_select "div.contact-activity", :count => 1
    end

    # Login as a moderator
    session[:user] = create(:moderator_user).id

    # Test the normal user
    get :show, :params => { :display_name => user.display_name }
    assert_response :success
    assert_select "div#userinformation" do
      assert_select "a[href^='/user/#{ERB::Util.u(user.display_name)}/history']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/traces']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/diary']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/diary/comments']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/account']", 0
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/blocks']", 0
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/blocks_by']", 0
      assert_select "a[href='/blocks/new/#{ERB::Util.u(user.display_name)}']", 1
    end
  end

  # Test whether information about contributor terms is shown for users who haven't agreed
  def test_terms_not_agreed
    agreed_user = create(:user, :terms_agreed => 3.days.ago)
    seen_user = create(:user, :terms_seen => true, :terms_agreed => nil)
    not_seen_user = create(:user, :terms_seen => false, :terms_agreed => nil)

    get :show, :params => { :display_name => agreed_user.display_name }
    assert_response :success
    assert_select "div#userinformation" do
      assert_select "p", :count => 0, :text => /Contributor terms/
    end

    get :show, :params => { :display_name => seen_user.display_name }
    assert_response :success
    # put @response.body
    assert_select "div#userinformation" do
      assert_select "p", :count => 1, :text => /Contributor terms/
      assert_select "p", /Declined/
    end

    get :show, :params => { :display_name => not_seen_user.display_name }
    assert_response :success
    assert_select "div#userinformation" do
      assert_select "p", :count => 1, :text => /Contributor terms/
      assert_select "p", /Undecided/
    end
  end

  def test_make_friend
    # Get users to work with
    user = create(:user)
    friend = create(:user)

    # Check that the users aren't already friends
    assert_nil Friendship.where(:befriender => user, :befriendee => friend).first

    # When not logged in a GET should ask us to login
    get :make_friend, :params => { :display_name => friend.display_name }
    assert_redirected_to :action => "login", :referer => make_friend_path(:display_name => friend.display_name)

    # When not logged in a POST should error
    post :make_friend, :params => { :display_name => friend.display_name }
    assert_response :forbidden
    assert_nil Friendship.where(:befriender => user, :befriendee => friend).first

    # When logged in a GET should get a confirmation page
    get :make_friend, :params => { :display_name => friend.display_name }, :session => { :user => user }
    assert_response :success
    assert_template :make_friend
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer']", 0
      assert_select "input[type='submit']", 1
    end
    assert_nil Friendship.where(:befriender => user, :befriendee => friend).first

    # When logged in a POST should add the friendship
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post :make_friend, :params => { :display_name => friend.display_name }, :session => { :user => user }
      end
    end
    assert_redirected_to user_path(friend)
    assert_match(/is now your friend/, flash[:notice])
    assert Friendship.where(:befriender => user, :befriendee => friend).first
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal friend.email, email.to.first
    ActionMailer::Base.deliveries.clear

    # A second POST should report that the friendship already exists
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        post :make_friend, :params => { :display_name => friend.display_name }, :session => { :user => user }
      end
    end
    assert_redirected_to user_path(friend)
    assert_match(/You are already friends with/, flash[:warning])
    assert Friendship.where(:befriender => user, :befriendee => friend).first
  end

  def test_make_friend_with_referer
    # Get users to work with
    user = create(:user)
    friend = create(:user)

    # Check that the users aren't already friends
    assert_nil Friendship.where(:befriender => user, :befriendee => friend).first

    # The GET should preserve any referer
    get :make_friend, :params => { :display_name => friend.display_name, :referer => "/test" }, :session => { :user => user }
    assert_response :success
    assert_template :make_friend
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer'][value='/test']", 1
      assert_select "input[type='submit']", 1
    end
    assert_nil Friendship.where(:befriender => user, :befriendee => friend).first

    # When logged in a POST should add the friendship and refer us
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post :make_friend, :params => { :display_name => friend.display_name, :referer => "/test" }, :session => { :user => user }
      end
    end
    assert_redirected_to "/test"
    assert_match(/is now your friend/, flash[:notice])
    assert Friendship.where(:befriender => user, :befriendee => friend).first
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal friend.email, email.to.first
    ActionMailer::Base.deliveries.clear
  end

  def test_make_friend_unkown_user
    # Should error when a bogus user is specified
    get :make_friend, :params => { :display_name => "No Such User" }, :session => { :user => create(:user) }
    assert_response :not_found
    assert_template :no_such_user
  end

  def test_remove_friend
    # Get users to work with
    user = create(:user)
    friend = create(:user)
    create(:friendship, :befriender => user, :befriendee => friend)

    # Check that the users are friends
    assert Friendship.where(:befriender => user, :befriendee => friend).first

    # When not logged in a GET should ask us to login
    get :remove_friend, :params => { :display_name => friend.display_name }
    assert_redirected_to :action => "login", :referer => remove_friend_path(:display_name => friend.display_name)

    # When not logged in a POST should error
    post :remove_friend, :params => { :display_name => friend.display_name }
    assert_response :forbidden
    assert Friendship.where(:befriender => user, :befriendee => friend).first

    # When logged in a GET should get a confirmation page
    get :remove_friend, :params => { :display_name => friend.display_name }, :session => { :user => user }
    assert_response :success
    assert_template :remove_friend
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer']", 0
      assert_select "input[type='submit']", 1
    end
    assert Friendship.where(:befriender => user, :befriendee => friend).first

    # When logged in a POST should remove the friendship
    post :remove_friend, :params => { :display_name => friend.display_name }, :session => { :user => user }
    assert_redirected_to user_path(friend)
    assert_match(/was removed from your friends/, flash[:notice])
    assert_nil Friendship.where(:befriender => user, :befriendee => friend).first

    # A second POST should report that the friendship does not exist
    post :remove_friend, :params => { :display_name => friend.display_name }, :session => { :user => user }
    assert_redirected_to user_path(friend)
    assert_match(/is not one of your friends/, flash[:error])
    assert_nil Friendship.where(:befriender => user, :befriendee => friend).first
  end

  def test_remove_friend_with_referer
    # Get users to work with
    user = create(:user)
    friend = create(:user)
    create(:friendship, :befriender => user, :befriendee => friend)

    # Check that the users are friends
    assert Friendship.where(:befriender => user, :befriendee => friend).first

    # The GET should preserve any referer
    get :remove_friend, :params => { :display_name => friend.display_name, :referer => "/test" }, :session => { :user => user }
    assert_response :success
    assert_template :remove_friend
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer'][value='/test']", 1
      assert_select "input[type='submit']", 1
    end
    assert Friendship.where(:befriender => user, :befriendee => friend).first

    # When logged in a POST should remove the friendship and refer
    post :remove_friend, :params => { :display_name => friend.display_name, :referer => "/test" }, :session => { :user => user }
    assert_redirected_to "/test"
    assert_match(/was removed from your friends/, flash[:notice])
    assert_nil Friendship.where(:befriender => user, :befriendee => friend).first
  end

  def test_remove_friend_unkown_user
    # Should error when a bogus user is specified
    get :remove_friend, :params => { :display_name => "No Such User" }, :session => { :user => create(:user) }
    assert_response :not_found
    assert_template :no_such_user
  end

  def test_set_status
    user = create(:user)

    # Try without logging in
    get :set_status, :params => { :display_name => user.display_name, :status => "suspended" }
    assert_response :redirect
    assert_redirected_to :action => :login, :referer => set_status_user_path(:status => "suspended")

    # Now try as a normal user
    get :set_status, :params => { :display_name => user.display_name, :status => "suspended" }, :session => { :user => user }
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Finally try as an administrator
    get :set_status, :params => { :display_name => user.display_name, :status => "suspended" }, :session => { :user => create(:administrator_user) }
    assert_response :redirect
    assert_redirected_to :action => :show, :display_name => user.display_name
    assert_equal "suspended", User.find(user.id).status
  end

  def test_delete
    user = create(:user, :home_lat => 12.1, :home_lon => 12.1, :description => "test")

    # Try without logging in
    get :delete, :params => { :display_name => user.display_name, :status => "suspended" }
    assert_response :redirect
    assert_redirected_to :action => :login, :referer => delete_user_path(:status => "suspended")

    # Now try as a normal user
    get :delete, :params => { :display_name => user.display_name, :status => "suspended" }, :session => { :user => user }
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Finally try as an administrator
    get :delete, :params => { :display_name => user.display_name, :status => "suspended" }, :session => { :user => create(:administrator_user) }
    assert_response :redirect
    assert_redirected_to :action => :show, :display_name => user.display_name

    # Check that the user was deleted properly
    user.reload
    assert_equal "user_#{user.id}", user.display_name
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

  def test_index_get
    user = create(:user)
    moderator_user = create(:moderator_user)
    administrator_user = create(:administrator_user)
    _suspended_user = create(:user, :suspended)
    _ip_user = create(:user, :creation_ip => "1.2.3.4")

    # There are now 7 users - the five above, plus two extra "granters" for the
    # moderator_user and administrator_user
    assert_equal 7, User.count

    # Shouldn't work when not logged in
    get :index
    assert_response :redirect
    assert_redirected_to :action => :login, :referer => users_path

    session[:user] = user.id

    # Shouldn't work when logged in as a normal user
    get :index
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    session[:user] = moderator_user.id

    # Shouldn't work when logged in as a moderator
    get :index
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    session[:user] = administrator_user.id

    # Note there is a header row, so all row counts are users + 1
    # Should work when logged in as an administrator
    get :index
    assert_response :success
    assert_template :index
    assert_select "table#user_list tr", :count => 7 + 1

    # Should be able to limit by status
    get :index, :params => { :status => "suspended" }
    assert_response :success
    assert_template :index
    assert_select "table#user_list tr", :count => 1 + 1

    # Should be able to limit by IP address
    get :index, :params => { :ip => "1.2.3.4" }
    assert_response :success
    assert_template :index
    assert_select "table#user_list tr", :count => 1 + 1
  end

  def test_index_get_paginated
    1.upto(100).each do |n|
      User.create(:display_name => "extra_#{n}",
                  :email => "extra#{n}@example.com",
                  :pass_crypt => "extraextra")
    end

    session[:user] = create(:administrator_user).id

    # 100 examples, an administrator, and a granter for the admin.
    assert_equal 102, User.count

    get :index
    assert_response :success
    assert_template :index
    assert_select "table#user_list tr", :count => 51

    get :index, :params => { :page => 2 }
    assert_response :success
    assert_template :index
    assert_select "table#user_list tr", :count => 51

    get :index, :params => { :page => 3 }
    assert_response :success
    assert_template :index
    assert_select "table#user_list tr", :count => 3
  end

  def test_index_post_confirm
    inactive_user = create(:user, :pending)
    suspended_user = create(:user, :suspended)

    # Shouldn't work when not logged in
    assert_no_difference "User.active.count" do
      post :index, :params => { :confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 } }
    end
    assert_response :forbidden

    assert_equal "pending", inactive_user.reload.status
    assert_equal "suspended", suspended_user.reload.status

    session[:user] = create(:user).id

    # Shouldn't work when logged in as a normal user
    assert_no_difference "User.active.count" do
      post :index, :params => { :confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 } }
    end
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert_equal "pending", inactive_user.reload.status
    assert_equal "suspended", suspended_user.reload.status

    session[:user] = create(:moderator_user).id

    # Shouldn't work when logged in as a moderator
    assert_no_difference "User.active.count" do
      post :index, :params => { :confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 } }
    end
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert_equal "pending", inactive_user.reload.status
    assert_equal "suspended", suspended_user.reload.status

    session[:user] = create(:administrator_user).id

    # Should work when logged in as an administrator
    assert_difference "User.active.count", 2 do
      post :index, :params => { :confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 } }
    end
    assert_response :redirect
    assert_redirected_to :action => :index
    assert_equal "confirmed", inactive_user.reload.status
    assert_equal "confirmed", suspended_user.reload.status
  end

  def test_index_post_hide
    normal_user = create(:user)
    confirmed_user = create(:user, :confirmed)

    # Shouldn't work when not logged in
    assert_no_difference "User.active.count" do
      post :index, :params => { :hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 } }
    end
    assert_response :forbidden

    assert_equal "active", normal_user.reload.status
    assert_equal "confirmed", confirmed_user.reload.status

    session[:user] = create(:user).id

    # Shouldn't work when logged in as a normal user
    assert_no_difference "User.active.count" do
      post :index, :params => { :hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 } }
    end
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert_equal "active", normal_user.reload.status
    assert_equal "confirmed", confirmed_user.reload.status

    session[:user] = create(:moderator_user).id

    # Shouldn't work when logged in as a moderator
    assert_no_difference "User.active.count" do
      post :index, :params => { :hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 } }
    end
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert_equal "active", normal_user.reload.status
    assert_equal "confirmed", confirmed_user.reload.status

    session[:user] = create(:administrator_user).id

    # Should work when logged in as an administrator
    assert_difference "User.active.count", -2 do
      post :index, :params => { :hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 } }
    end
    assert_response :redirect
    assert_redirected_to :action => :index
    assert_equal "deleted", normal_user.reload.status
    assert_equal "deleted", confirmed_user.reload.status
  end
end
