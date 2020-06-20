require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
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
      { :path => "/user/username/set_status", :method => :post },
      { :controller => "users", :action => "set_status", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username", :method => :delete },
      { :controller => "users", :action => "destroy", :display_name => "username" }
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
    get user_new_path
    assert_response :redirect
    assert_redirected_to user_new_path(:cookie_test => "true")

    get user_new_path, :params => { :cookie_test => "true" }
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
    session_for(create(:user))

    get user_new_path
    assert_response :redirect
    assert_redirected_to root_path

    get user_new_path, :params => { :referer => "/test" }
    assert_response :redirect
    assert_redirected_to "/test"
  end

  def test_new_success
    user = build(:user, :pending)

    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post user_new_path, :params => { :user => user.attributes }
        end
      end
    end

    assert_difference "User.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        perform_enqueued_jobs do
          post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
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
    create(:user, :email => user.email)

    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post user_new_path, :params => { :user => user.attributes }
        end
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.standard-form-row > input.field_with_errors#user_email"
  end

  def test_save_duplicate_email
    user = build(:user, :pending)

    # Set up our user as being half-way through registration
    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post user_new_path, :params => { :user => user.attributes }
        end
      end
    end

    # Now create another user with that email
    create(:user, :email => user.email)

    # Check that the second half of registration fails
    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
        end
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.standard-form-row > input.field_with_errors#user_email"
  end

  def test_save_duplicate_email_uppercase
    user = build(:user, :pending)

    # Set up our user as being half-way through registration
    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post user_new_path, :params => { :user => user.attributes }
        end
      end
    end

    # Now create another user with that email, but uppercased
    create(:user, :email => user.email.upcase)

    # Check that the second half of registration fails
    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
        end
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.standard-form-row > input.field_with_errors#user_email"
  end

  def test_save_duplicate_name
    user = build(:user, :pending)

    # Set up our user as being half-way through registration
    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post user_new_path, :params => { :user => user.attributes }
        end
      end
    end

    # Now create another user with that display name
    create(:user, :display_name => user.display_name)

    # Check that the second half of registration fails
    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
        end
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.standard-form-row > input.field_with_errors#user_display_name"
  end

  def test_save_duplicate_name_uppercase
    user = build(:user, :pending)

    # Set up our user as being half-way through registration
    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post user_new_path, :params => { :user => user.attributes }
        end
      end
    end

    # Now create another user with that display_name, but uppercased
    create(:user, :display_name => user.display_name.upcase)

    # Check that the second half of registration fails
    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
        end
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.standard-form-row > input.field_with_errors#user_display_name"
  end

  def test_save_blocked_domain
    user = build(:user, :pending, :email => "user@example.net")

    # Set up our user as being half-way through registration
    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post user_new_path, :params => { :user => user.attributes }
        end
      end
    end

    # Now block that domain
    create(:acl, :domain => "example.net", :k => "no_account_creation")

    # Check that the second half of registration fails
    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
        end
      end
    end

    assert_response :success
    assert_template "blocked"
  end

  def test_save_referer_params
    user = build(:user, :pending)

    # Set up our user as being half-way through registration
    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post user_new_path, :params => { :user => user.attributes, :referer => "/edit?editor=id#map=1/2/3" }
        end
      end
    end

    assert_difference "User.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        perform_enqueued_jobs do
          post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
        end
      end
    end

    assert_equal welcome_path(:editor => "id", :zoom => 1, :lat => 2, :lon => 3),
                 User.find_by(:email => user.email).tokens.order("id DESC").first.referer

    ActionMailer::Base.deliveries.clear
  end

  def test_logout_without_referer
    post logout_path
    assert_response :redirect
    assert_redirected_to root_path
  end

  def test_logout_with_referer
    post logout_path, :params => { :referer => "/test" }
    assert_response :redirect
    assert_redirected_to "/test"
  end

  def test_logout_fallback_without_referer
    get logout_path
    assert_response :success
    assert_template :logout
    assert_select "input[name=referer][value=?]", ""
  end

  def test_logout_fallback_with_referer
    get logout_path, :params => { :referer => "/test" }
    assert_response :success
    assert_template :logout
    assert_select "input[name=referer][value=?]", "/test"
  end

  def test_logout_removes_session_token
    user = build(:user, :pending)
    post user_new_path, :params => { :user => user.attributes }
    post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }

    assert_difference "User.find_by(:email => user.email).tokens.count", -1 do
      post logout_path
    end
    assert_response :redirect
    assert_redirected_to root_path
  end

  def test_confirm_get
    user = build(:user, :pending)
    post user_new_path, :params => { :user => user.attributes }
    post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
    confirm_string = User.find_by(:email => user.email).tokens.create.token

    get user_confirm_path, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_response :success
    assert_template :confirm
  end

  def test_confirm_get_already_confirmed
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post user_new_path, :params => { :user => user.attributes }
    post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
    confirm_string = User.find_by(:email => user.email).tokens.create.token

    # Get the confirmation page
    get user_confirm_path, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_response :success
    assert_template :confirm

    # Confirm the user
    post user_confirm_path, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_redirected_to welcome_path

    # Now try to get the confirmation page again
    get user_confirm_path, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_response :redirect
    assert_redirected_to root_path
  end

  def test_confirm_success_no_token_no_referer
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post user_new_path, :params => { :user => user.attributes }
    post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
    confirm_string = User.find_by(:email => user.email).tokens.create.token

    post logout_path

    post user_confirm_path, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_redirected_to login_path
    assert_match(/Confirmed your account/, flash[:notice])
  end

  def test_confirm_success_good_token_no_referer
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post user_new_path, :params => { :user => user.attributes }
    post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
    confirm_string = User.find_by(:email => user.email).tokens.create.token

    post user_confirm_path, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_redirected_to welcome_path
  end

  def test_confirm_success_bad_token_no_referer
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post user_new_path, :params => { :user => user.attributes }
    post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
    confirm_string = User.find_by(:email => user.email).tokens.create.token

    post logout_path
    session_for(create(:user))

    post user_confirm_path, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_redirected_to login_path
    assert_match(/Confirmed your account/, flash[:notice])
  end

  def test_confirm_success_no_token_with_referer
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post user_new_path, :params => { :user => user.attributes }
    post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
    confirm_string = User.find_by(:email => user.email).tokens.create(:referer => new_diary_entry_path).token

    post logout_path

    post user_confirm_path, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_redirected_to login_path(:referer => new_diary_entry_path)
    assert_match(/Confirmed your account/, flash[:notice])
  end

  def test_confirm_success_good_token_with_referer
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post user_new_path, :params => { :user => user.attributes }
    post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
    confirm_string = User.find_by(:email => user.email).tokens.create(:referer => new_diary_entry_path).token

    post user_confirm_path, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_redirected_to new_diary_entry_path
  end

  def test_confirm_success_bad_token_with_referer
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post user_new_path, :params => { :user => user.attributes }
    post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
    confirm_string = User.find_by(:email => user.email).tokens.create(:referer => new_diary_entry_path).token

    post logout_path
    session_for(create(:user))

    post user_confirm_path, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_redirected_to login_path(:referer => new_diary_entry_path)
    assert_match(/Confirmed your account/, flash[:notice])
  end

  def test_confirm_expired_token
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post user_new_path, :params => { :user => user.attributes }
    post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
    confirm_string = User.find_by(:email => user.email).tokens.create(:expiry => 1.day.ago).token

    post user_confirm_path, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_redirected_to :action => "confirm"
    assert_match(/confirmation code has expired/, flash[:error])
  end

  def test_confirm_already_confirmed
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post user_new_path, :params => { :user => user.attributes }
    post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
    confirm_string = User.find_by(:email => user.email).tokens.create(:referer => new_diary_entry_path).token

    post user_confirm_path, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_redirected_to new_diary_entry_path

    post logout_path

    confirm_string = User.find_by(:email => user.email).tokens.create(:referer => new_diary_entry_path).token
    post user_confirm_path, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_redirected_to :action => "login"
    assert_match(/already been confirmed/, flash[:error])
  end

  def test_confirm_resend_success
    user = build(:user, :pending)
    post user_new_path, :params => { :user => user.attributes }
    post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }

    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        get user_confirm_resend_path(user)
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
    user = build(:user, :pending)
    # only complete first half of registration
    post user_new_path, :params => { :user => user.attributes }

    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        get user_confirm_resend_path(user)
      end
    end

    assert_response :redirect
    assert_redirected_to login_path
    assert_match "User #{user.display_name} not found.", flash[:error]
  end

  def test_confirm_resend_unknown_user
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        get user_confirm_resend_path(:display_name => "No Such User")
      end
    end

    assert_response :redirect
    assert_redirected_to login_path
    assert_match "User No Such User not found.", flash[:error]
  end

  def test_confirm_email_get
    user = create(:user)
    confirm_string = user.tokens.create.token

    get user_confirm_email_path, :params => { :confirm_string => confirm_string }
    assert_response :success
    assert_template :confirm_email
  end

  def test_confirm_email_success
    user = create(:user, :new_email => "test-new@example.com")
    stub_gravatar_request(user.new_email)
    confirm_string = user.tokens.create.token

    post user_confirm_email_path, :params => { :confirm_string => confirm_string }
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
    assert_match(/Confirmed your change of email address/, flash[:notice])
  end

  def test_confirm_email_already_confirmed
    user = create(:user)
    confirm_string = user.tokens.create.token

    post user_confirm_email_path, :params => { :confirm_string => confirm_string }
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
    assert_match(/already been confirmed/, flash[:error])
  end

  def test_confirm_email_bad_token
    post user_confirm_email_path, :params => { :confirm_string => "XXXXX" }
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
    post user_confirm_email_path, :params => { :confirm_string => confirm_string }
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
    post user_confirm_email_path, :params => { :confirm_string => confirm_string }
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
    assert_match(/Confirmed your change of email address/, flash[:notice])
    # gravatar use should now be disabled
    assert_not User.find(user.id).image_use_gravatar
  end

  def test_terms_new_user
    user = build(:user, :pending)

    # Set up our user as being half-way through registration
    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post user_new_path, :params => { :user => user.attributes }
        end
      end
    end

    get user_terms_path

    assert_response :success
    assert_template :terms
  end

  def test_terms_agreed
    user = create(:user, :terms_seen => true, :terms_agreed => Date.yesterday)

    session_for(user)

    get user_terms_path
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
  end

  def test_terms_not_seen_without_referer
    user = create(:user, :terms_seen => false, :terms_agreed => nil)

    session_for(user)

    get user_terms_path
    assert_response :success
    assert_template :terms

    post user_save_path, :params => { :user => { :consider_pd => true }, :read_ct => 1, :read_tou => 1 }
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
    assert_equal "Thanks for accepting the new contributor terms!", flash[:notice]

    user.reload

    assert user.consider_pd
    assert_not_nil user.terms_agreed
    assert user.terms_seen
  end

  def test_terms_not_seen_with_referer
    user = create(:user, :terms_seen => false, :terms_agreed => nil)

    session_for(user)

    get user_terms_path, :params => { :referer => "/test" }
    assert_response :success
    assert_template :terms

    post user_save_path, :params => { :user => { :consider_pd => true }, :referer => "/test", :read_ct => 1, :read_tou => 1 }
    assert_response :redirect
    assert_redirected_to "/test"
    assert_equal "Thanks for accepting the new contributor terms!", flash[:notice]

    user.reload

    assert user.consider_pd
    assert_not_nil user.terms_agreed
    assert user.terms_seen
  end

  # Check that if you haven't seen the terms, and make a request that requires authentication,
  # that your request is redirected to view the terms
  def test_terms_not_seen_redirection
    user = create(:user, :terms_seen => false, :terms_agreed => nil)
    session_for(user)

    get user_account_path(user)
    assert_response :redirect
    assert_redirected_to :action => :terms, :referer => "/user/#{ERB::Util.u(user.display_name)}/account"
  end

  def test_go_public
    user = create(:user, :data_public => false)
    session_for(user)

    post user_go_public_path

    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
    assert User.find(user.id).data_public
  end

  def test_lost_password
    # Test fetching the lost password page
    get user_forgot_password_path
    assert_response :success
    assert_template :lost_password
    assert_select "div#notice", false

    # Test resetting using the address as recorded for a user that has an
    # address which is duplicated in a different case by another user
    user = create(:user)
    uppercase_user = build(:user, :email => user.email.upcase).tap { |u| u.save(:validate => false) }

    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post user_forgot_password_path, :params => { :user => { :email => user.email } }
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
        post user_forgot_password_path, :params => { :user => { :email => user.email.upcase } }
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
        post user_forgot_password_path, :params => { :user => { :email => user.email.titlecase } }
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
        post user_forgot_password_path, :params => { :user => { :email => third_user.email } }
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
        post user_forgot_password_path, :params => { :user => { :email => third_user.email.upcase } }
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
    get user_reset_password_path
    assert_response :bad_request

    # Test a request with a bogus token
    get user_reset_password_path, :params => { :token => "made_up_token" }
    assert_response :redirect
    assert_redirected_to :action => :lost_password

    # Create a valid token for a user
    token = user.tokens.create

    # Test a request with a valid token
    get user_reset_password_path, :params => { :token => token.token }
    assert_response :success
    assert_template :reset_password

    # Test that errors are reported for erroneous submissions
    post user_reset_password_path, :params => { :token => token.token, :user => { :pass_crypt => "new_password", :pass_crypt_confirmation => "different_password" } }
    assert_response :success
    assert_template :reset_password
    assert_select "div#errorExplanation"

    # Test setting a new password
    post user_reset_password_path, :params => { :token => token.token, :user => { :pass_crypt => "new_password", :pass_crypt_confirmation => "new_password" } }
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal user.id, session[:user]
    user.reload
    assert_equal "active", user.status
    assert user.email_valid
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
    get user_account_path(user)
    assert_response :redirect
    assert_redirected_to :action => "login", :referer => "/user/#{ERB::Util.u(user.display_name)}/account"

    # Make sure that you are blocked when not logged in as the right user
    session_for(create(:user))
    get user_account_path(user)
    assert_response :forbidden

    # Make sure we get the page when we are logged in as the right user
    session_for(user)
    get user_account_path(user)
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
    post user_account_path(user), :params => { :user => user.attributes }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.standard-form-row > div#user_description_container > div#user_description_content > textarea#user_description", user.description

    # Changing to a invalid editor should fail
    user.preferred_editor = "unknown"
    post user_account_path(user), :params => { :user => user.attributes }
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.standard-form-row > select#user_preferred_editor > option[selected]", false

    # Changing to a valid editor should work
    user.preferred_editor = "potlatch2"
    post user_account_path(user), :params => { :user => user.attributes }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.standard-form-row > select#user_preferred_editor > option[selected][value=?]", "potlatch2"

    # Changing to the default editor should work
    user.preferred_editor = "default"
    post user_account_path(user), :params => { :user => user.attributes }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.standard-form-row > select#user_preferred_editor > option[selected]", false

    # Changing to an uploaded image should work
    image = Rack::Test::UploadedFile.new("test/gpx/fixtures/a.gif", "image/gif")
    post user_account_path(user), :params => { :avatar_action => "new", :user => user.attributes.merge(:avatar => image) }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.standard-form-row.accountImage input[name=avatar_action][checked][value=?]", "keep"

    # Changing to a gravatar image should work
    post user_account_path(user), :params => { :avatar_action => "gravatar", :user => user.attributes }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.standard-form-row.accountImage input[name=avatar_action][checked][value=?]", "gravatar"

    # Removing the image should work
    post user_account_path(user), :params => { :avatar_action => "delete", :user => user.attributes }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.standard-form-row.accountImage input[name=avatar_action][checked]", false

    # Adding external authentication should redirect to the auth provider
    post user_account_path(user), :params => { :user => user.attributes.merge(:auth_provider => "openid", :auth_uid => "gmail.com") }
    assert_response :redirect
    assert_redirected_to auth_path(:provider => "openid", :openid_url => "https://www.google.com/accounts/o8/id", :origin => "/user/#{ERB::Util.u(user.display_name)}/account")

    # Changing name to one that exists should fail
    new_attributes = user.attributes.dup.merge(:display_name => create(:user).display_name)
    post user_account_path(user), :params => { :user => new_attributes }
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.standard-form-row > input.field_with_errors#user_display_name"

    # Changing name to one that exists should fail, regardless of case
    new_attributes = user.attributes.dup.merge(:display_name => create(:user).display_name.upcase)
    post user_account_path(user), :params => { :user => new_attributes }
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.standard-form-row > input.field_with_errors#user_display_name"

    # Changing name to one that doesn't exist should work
    new_attributes = user.attributes.dup.merge(:display_name => "new tester")
    post user_account_path(user), :params => { :user => new_attributes }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.standard-form-row > input#user_display_name[value=?]", "new tester"

    # Record the change of name
    user.display_name = "new tester"

    # Changing email to one that exists should fail
    user.new_email = create(:user).email
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        post user_account_path(user), :params => { :user => user.attributes }
      end
    end
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.standard-form-row > input.field_with_errors#user_new_email"

    # Changing email to one that exists should fail, regardless of case
    user.new_email = create(:user).email.upcase
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        post user_account_path(user), :params => { :user => user.attributes }
      end
    end
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.standard-form-row > input.field_with_errors#user_new_email"

    # Changing email to one that doesn't exist should work
    user.new_email = "new_tester@example.com"
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post user_account_path(user), :params => { :user => user.attributes }
      end
    end
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.standard-form-row > input#user_new_email[value=?]", user.new_email
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal user.new_email, email.to.first
    ActionMailer::Base.deliveries.clear
  end

  # Check that the user account page will display and contains some relevant
  # information for the user
  def test_show
    # Test a non-existent user
    get user_path(:display_name => "unknown")
    assert_response :not_found

    # Test a normal user
    user = create(:user, :home_lon => 1.1, :home_lat => 1.1)
    friend_user = create(:user, :home_lon => 1.2, :home_lat => 1.2)
    create(:friendship, :befriender => user, :befriendee => friend_user)
    create(:changeset, :user => friend_user)

    get user_path(user)
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
    get user_path(blocked_user)
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
    get user_path(moderator_user)
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
    session_for(user)

    # Test the normal user
    get user_path(user)
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
    session_for(create(:moderator_user))

    # Test the normal user
    get user_path(user)
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

    get user_path(agreed_user)
    assert_response :success
    assert_select "div#userinformation" do
      assert_select "p", :count => 0, :text => /Contributor terms/
    end

    get user_path(seen_user)
    assert_response :success
    # put @response.body
    assert_select "div#userinformation" do
      assert_select "p", :count => 1, :text => /Contributor terms/
      assert_select "p", /Declined/
    end

    get user_path(not_seen_user)
    assert_response :success
    assert_select "div#userinformation" do
      assert_select "p", :count => 1, :text => /Contributor terms/
      assert_select "p", /Undecided/
    end
  end

  def test_set_status
    user = create(:user)

    # Try without logging in
    post set_status_user_path(user), :params => { :status => "suspended" }
    assert_response :forbidden

    # Now try as a normal user
    session_for(user)
    post set_status_user_path(user), :params => { :status => "suspended" }
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Finally try as an administrator
    session_for(create(:administrator_user))
    post set_status_user_path(user), :params => { :status => "suspended" }
    assert_response :redirect
    assert_redirected_to :action => :show, :display_name => user.display_name
    assert_equal "suspended", User.find(user.id).status
  end

  def test_destroy
    user = create(:user, :home_lat => 12.1, :home_lon => 12.1, :description => "test")

    # Try without logging in
    delete user_path(user), :params => { :status => "suspended" }
    assert_response :forbidden

    # Now try as a normal user
    session_for(user)
    delete user_path(user), :params => { :status => "suspended" }
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Finally try as an administrator
    session_for(create(:administrator_user))
    delete user_path(user), :params => { :status => "suspended" }
    assert_response :redirect
    assert_redirected_to :action => :show, :display_name => user.display_name

    # Check that the user was deleted properly
    user.reload
    assert_equal "user_#{user.id}", user.display_name
    assert_equal "", user.description
    assert_nil user.home_lat
    assert_nil user.home_lon
    assert_not user.avatar.attached?
    assert_not user.email_valid
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
    get users_path
    assert_response :redirect
    assert_redirected_to :action => :login, :referer => users_path

    session_for(user)

    # Shouldn't work when logged in as a normal user
    get users_path
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    session_for(moderator_user)

    # Shouldn't work when logged in as a moderator
    get users_path
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    session_for(administrator_user)

    # Note there is a header row, so all row counts are users + 1
    # Should work when logged in as an administrator
    get users_path
    assert_response :success
    assert_template :index
    assert_select "table#user_list tr", :count => 7 + 1

    # Should be able to limit by status
    get users_path, :params => { :status => "suspended" }
    assert_response :success
    assert_template :index
    assert_select "table#user_list tr", :count => 1 + 1

    # Should be able to limit by IP address
    get users_path, :params => { :ip => "1.2.3.4" }
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

    session_for(create(:administrator_user))

    # 100 examples, an administrator, and a granter for the admin.
    assert_equal 102, User.count

    get users_path
    assert_response :success
    assert_template :index
    assert_select "table#user_list tr", :count => 51

    get users_path, :params => { :page => 2 }
    assert_response :success
    assert_template :index
    assert_select "table#user_list tr", :count => 51

    get users_path, :params => { :page => 3 }
    assert_response :success
    assert_template :index
    assert_select "table#user_list tr", :count => 3
  end

  def test_index_post_confirm
    inactive_user = create(:user, :pending)
    suspended_user = create(:user, :suspended)

    # Shouldn't work when not logged in
    assert_no_difference "User.active.count" do
      post users_path, :params => { :confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 } }
    end
    assert_response :forbidden

    assert_equal "pending", inactive_user.reload.status
    assert_equal "suspended", suspended_user.reload.status

    session_for(create(:user))

    # Shouldn't work when logged in as a normal user
    assert_no_difference "User.active.count" do
      post users_path, :params => { :confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 } }
    end
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert_equal "pending", inactive_user.reload.status
    assert_equal "suspended", suspended_user.reload.status

    session_for(create(:moderator_user))

    # Shouldn't work when logged in as a moderator
    assert_no_difference "User.active.count" do
      post users_path, :params => { :confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 } }
    end
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert_equal "pending", inactive_user.reload.status
    assert_equal "suspended", suspended_user.reload.status

    session_for(create(:administrator_user))

    # Should work when logged in as an administrator
    assert_difference "User.active.count", 2 do
      post users_path, :params => { :confirm => 1, :user => { inactive_user.id => 1, suspended_user.id => 1 } }
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
      post users_path, :params => { :hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 } }
    end
    assert_response :forbidden

    assert_equal "active", normal_user.reload.status
    assert_equal "confirmed", confirmed_user.reload.status

    session_for(create(:user))

    # Shouldn't work when logged in as a normal user
    assert_no_difference "User.active.count" do
      post users_path, :params => { :hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 } }
    end
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert_equal "active", normal_user.reload.status
    assert_equal "confirmed", confirmed_user.reload.status

    session_for(create(:moderator_user))

    # Shouldn't work when logged in as a moderator
    assert_no_difference "User.active.count" do
      post users_path, :params => { :hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 } }
    end
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert_equal "active", normal_user.reload.status
    assert_equal "confirmed", confirmed_user.reload.status

    session_for(create(:administrator_user))

    # Should work when logged in as an administrator
    assert_difference "User.active.count", -2 do
      post users_path, :params => { :hide => 1, :user => { normal_user.id => 1, confirmed_user.id => 1 } }
    end
    assert_response :redirect
    assert_redirected_to :action => :index
    assert_equal "deleted", normal_user.reload.status
    assert_equal "deleted", confirmed_user.reload.status
  end
end
