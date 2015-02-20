require "test_helper"

class UserControllerTest < ActionController::TestCase
  fixtures :users

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
  def test_user_create_view
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

  def test_user_create_success
    user = new_user

    assert_difference("User.count", 1) do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
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

  def test_user_create_submit_duplicate_email
    user = new_user
    user.email = users(:public_user).email

    assert_no_difference("User.count") do
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        post :save, {}, { :new_user => user }
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.form-row > input.field_with_errors#user_email"
  end

  def test_user_create_submit_duplicate_email_uppercase
    user = new_user
    user.email = users(:public_user).email.upcase

    assert_no_difference("User.count") do
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        post :save, {}, { :new_user => user }
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.form-row > input.field_with_errors#user_email"
  end

  def test_user_create_submit_duplicate_name
    user = new_user
    user.display_name = users(:public_user).display_name

    assert_no_difference("User.count") do
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        post :save, {}, { :new_user => user }
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.form-row > input.field_with_errors#user_display_name"
  end

  def test_user_create_submit_duplicate_name_uppercase
    user = new_user
    user.display_name = users(:public_user).display_name.upcase

    assert_no_difference("User.count") do
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        post :save, {}, { :new_user => user }
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > fieldset > div.form-row > input.field_with_errors#user_display_name"
  end

  def test_user_save_referer_params
    user = new_user

    assert_difference("User.count", 1) do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        post :save, {}, { :new_user => user,
                          :referer => "/edit?editor=id#map=1/2/3" }
      end
    end

    assert_equal welcome_path(:editor => "id", :zoom => 1, :lat => 2, :lon => 3),
                 user.tokens.order("id DESC").first.referer

    ActionMailer::Base.deliveries.clear
  end

  def test_user_confirm_expired_token
    user = users(:inactive_user)
    token = user.tokens.new
    token.expiry = 1.day.ago
    token.save!

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, :confirm_string => token.token

    assert_redirected_to :action => "confirm"
    assert_match /expired/, flash[:error]
  end

  def test_user_already_confirmed
    user = users(:normal_user)
    token = user.tokens.create

    @request.cookies["_osm_session"] = user.display_name
    post :confirm, :confirm_string => token.token

    assert_redirected_to :action => "login"
    assert_match /confirmed/, flash[:error]
  end

  def test_user_terms_new_user
    get :terms, {}, { "new_user" => User.new }
    assert_response :success
    assert_template :terms
  end

  def test_user_terms_seen
    user = users(:normal_user)

    get :terms, {}, { "user" => user }
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => user.display_name
  end

  def test_user_go_public
    post :go_public, {}, { :user => users(:normal_user) }
    assert_response :redirect
    assert_redirected_to :action => :account, :display_name => users(:normal_user).display_name
    assert_equal true, User.find(users(:normal_user).id).data_public
  end

  def test_user_lost_password
    # Test fetching the lost password page
    get :lost_password
    assert_response :success
    assert_template :lost_password
    assert_select "div#notice", false

    # Test resetting using the address as recorded for a user that has an
    # address which is duplicated in a different case by another user
    assert_difference("ActionMailer::Base.deliveries.size", 1) do
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
    assert_difference("ActionMailer::Base.deliveries.size", 1) do
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
    assert_difference("ActionMailer::Base.deliveries.size", 0) do
      post :lost_password, :user => { :email => users(:normal_user).email.titlecase }
    end
    assert_response :success
    assert_template :lost_password
    assert_select ".error", /^Could not find that email address/

    # Test resetting using the address as recorded for a user that has an
    # address which is case insensitively unique
    assert_difference("ActionMailer::Base.deliveries.size", 1) do
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
    assert_difference("ActionMailer::Base.deliveries.size", 1) do
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
    assert_redirected_to :action => :login
    user = User.find(users(:inactive_user).id)
    assert_equal "active", user.status
    assert_equal true, user.email_valid
    assert_equal user, User.authenticate(:username => "inactive@openstreetmap.org", :password => "new_password")
  end

  def test_user_update
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
    get :account, { :display_name => user.display_name }, { "user" => users(:public_user).id }
    assert_response :forbidden

    # Make sure we get the page when we are logged in as the right user
    get :account, { :display_name => user.display_name }, { "user" => user }
    assert_response :success
    assert_template :account

    # Updating the description should work
    user.description = "new description"
    post :account, { :display_name => user.display_name, :user => user.attributes }, { "user" => user.id }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row > div#user_description_container > div#user_description_content > textarea#user_description", user.description

    # Changing name to one that exists should fail
    new_attributes = user.attributes.dup.merge(:display_name => users(:public_user).display_name)
    post :account, { :display_name => user.display_name, :user => new_attributes }, { "user" => user.id }
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.form-row > input.field_with_errors#user_display_name"

    # Changing name to one that exists should fail, regardless of case
    new_attributes = user.attributes.dup.merge(:display_name => users(:public_user).display_name.upcase)
    post :account, { :display_name => user.display_name, :user => new_attributes }, { "user" => user.id }
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.form-row > input.field_with_errors#user_display_name"

    # Changing name to one that doesn't exist should work
    new_attributes = user.attributes.dup.merge(:display_name => "new tester")
    post :account, { :display_name => user.display_name, :user => new_attributes }, { "user" => user.id }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select ".notice", /^User information updated successfully/
    assert_select "form#accountForm > fieldset > div.form-row > input#user_display_name[value=?]", "new tester"

    # Record the change of name
    user.display_name = "new tester"

    # Changing email to one that exists should fail
    user.new_email = users(:public_user).email
    assert_no_difference("ActionMailer::Base.deliveries.size") do
      post :account, { :display_name => user.display_name, :user => user.attributes }, { "user" => user.id }
    end
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.form-row > input.field_with_errors#user_new_email"

    # Changing email to one that exists should fail, regardless of case
    user.new_email = users(:public_user).email.upcase
    assert_no_difference("ActionMailer::Base.deliveries.size") do
      post :account, { :display_name => user.display_name, :user => user.attributes }, { "user" => user.id }
    end
    assert_response :success
    assert_template :account
    assert_select ".notice", false
    assert_select "div#errorExplanation"
    assert_select "form#accountForm > fieldset > div.form-row > input.field_with_errors#user_new_email"

    # Changing email to one that doesn't exist should work
    user.new_email = "new_tester@example.com"
    assert_difference("ActionMailer::Base.deliveries.size", 1) do
      post :account, { :display_name => user.display_name, :user => user.attributes }, { "user" => user.id }
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
  def test_user_view_account
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

  def test_user_api_read
    # check that a visible user is returned properly
    get :api_read, :id => users(:normal_user).id
    assert_response :success

    # check the data that is returned
    assert_select "description", :count => 1, :text => "test"
    assert_select "contributor-terms", :count => 1 do
      assert_select "[agreed='true']"
    end
    assert_select "img", :count => 1
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

  def test_user_api_details
    # check that nothing is returned when not logged in
    get :api_details
    assert_response :unauthorized

    # check that we get a response when logged in
    basic_authorization(users(:normal_user).email, "test")
    get :api_details
    assert_response :success

    # check the data that is returned
    assert_select "description", :count => 1, :text => "test"
    assert_select "contributor-terms", :count => 1 do
      assert_select "[agreed='true'][pd='false']"
    end
    assert_select "img", :count => 1
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

  def test_user_make_friend
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
    get :make_friend, { :display_name => friend.display_name }, { "user" => user }
    assert_response :success
    assert_template :make_friend
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer']", 0
      assert_select "input[type='submit']", 1
    end
    assert_nil Friend.where(:user_id => user.id, :friend_user_id => friend.id).first

    # The GET should preserve any referer
    get :make_friend, { :display_name => friend.display_name, :referer => "/test" }, { "user" => user }
    assert_response :success
    assert_template :make_friend
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer'][value='/test']", 1
      assert_select "input[type='submit']", 1
    end
    assert_nil Friend.where(:user_id => user.id, :friend_user_id => friend.id).first

    # When logged in a POST should add the friendship
    assert_difference("ActionMailer::Base.deliveries.size", 1) do
      post :make_friend, { :display_name => friend.display_name }, { "user" => user }
    end
    assert_redirected_to user_path(:display_name => friend.display_name)
    assert_match /is now your friend/, flash[:notice]
    assert Friend.where(:user_id => user.id, :friend_user_id => friend.id).first
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal friend.email, email.to.first
    ActionMailer::Base.deliveries.clear

    # A second POST should report that the friendship already exists
    assert_no_difference("ActionMailer::Base.deliveries.size") do
      post :make_friend, { :display_name => friend.display_name }, { "user" => user }
    end
    assert_redirected_to user_path(:display_name => friend.display_name)
    assert_match /You are already friends with/, flash[:warning]
    assert Friend.where(:user_id => user.id, :friend_user_id => friend.id).first
  end

  def test_user_remove_friend
    # Get users to work with
    user = users(:normal_user)
    friend = users(:public_user)

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
    get :remove_friend, { :display_name => friend.display_name }, { "user" => user }
    assert_response :success
    assert_template :remove_friend
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer']", 0
      assert_select "input[type='submit']", 1
    end
    assert Friend.where(:user_id => user.id, :friend_user_id => friend.id).first

    # The GET should preserve any referer
    get :remove_friend, { :display_name => friend.display_name, :referer => "/test" }, { "user" => user }
    assert_response :success
    assert_template :remove_friend
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer'][value='/test']", 1
      assert_select "input[type='submit']", 1
    end
    assert Friend.where(:user_id => user.id, :friend_user_id => friend.id).first

    # When logged in a POST should remove the friendship
    post :remove_friend, { :display_name => friend.display_name }, { "user" => user }
    assert_redirected_to user_path(:display_name => friend.display_name)
    assert_match /was removed from your friends/, flash[:notice]
    assert_nil Friend.where(:user_id => user.id, :friend_user_id => friend.id).first

    # A second POST should report that the friendship does not exist
    post :remove_friend, { :display_name => friend.display_name }, { "user" => user }
    assert_redirected_to user_path(:display_name => friend.display_name)
    assert_match /is not one of your friends/, flash[:error]
    assert_nil Friend.where(:user_id => user.id, :friend_user_id => friend.id).first
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
    assert_nil user.openid_url
    assert_equal "deleted", user.status
  end
end
