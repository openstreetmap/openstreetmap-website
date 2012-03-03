require File.dirname(__FILE__) + '/../test_helper'

class UserControllerTest < ActionController::TestCase
  fixtures :users
  
  ##
  # test all routes which lead to this controller
  def test_routes
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
    assert_recognizes(
      { :controller => "user", :action => "new" },
      { :path => "/create-account.html", :method => :get }
    )

    assert_routing(
      { :path => "/user/terms", :method => :get },
      { :controller => "user", :action => "terms" }
    )
    assert_routing(
      { :path => "/user/terms", :method => :post },
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
    assert_recognizes(
      { :controller => "user", :action => "lost_password" },
      { :path => "/forgot-password.html", :method => :get }
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
      { :path => "/user/username/remove_friend", :method => :get },
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
    assert_response :success
    
    assert_select "html", :count => 1 do
      assert_select "head", :count => 1 do
        assert_select "title", :text => /Create account/, :count => 1
      end
      assert_select "body", :count => 1 do
        assert_select "div#content", :count => 1 do
          assert_select "form[action='/user/terms'][method=post]", :count => 1 do
            assert_select "input[id=user_email]", :count => 1
            assert_select "input[id=user_email_confirmation]", :count => 1
            assert_select "input[id=user_display_name]", :count => 1
            assert_select "input[id=user_pass_crypt][type=password]", :count => 1
            assert_select "input[id=user_pass_crypt_confirmation][type=password]", :count => 1
            assert_select "input[type=submit][value=Continue]", :count => 1
          end
        end
      end
    end
  end
  
  def test_user_create_success
    new_email = "newtester@osm.org"
    display_name = "new_tester"
    assert_difference('User.count') do
      assert_difference('ActionMailer::Base.deliveries.size') do
        post :save, {:user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest"}}
      end
    end
      
    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first
  
    assert_equal register_email.to[0], new_email
    assert_match /#{@url}/, register_email.body

    # Check the page
    assert_redirected_to :action => 'login', :referer => nil
      
    ActionMailer::Base.deliveries.clear
  end
  
  def test_user_create_submit_duplicate_email
    email = users(:public_user).email
    display_name = "new_tester"
    assert_difference('User.count', 0) do
      assert_difference('ActionMailer::Base.deliveries.size', 0) do
        post :save, :user => { :email => email, :email_confirmation => email, :display_name => display_name, :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest"}
      end
    end
    assert_response :success                                                                       
    assert_template 'new'
    assert_select "div#errorExplanation"
    assert_select "table#signupForm > tr > td > div[class=field_with_errors] > input#user_email"
  end
  
  def test_user_create_submit_duplicate_email_uppercase
    email = users(:public_user).email.upcase
    display_name = "new_tester"
    assert_difference('User.count', 0) do
      assert_difference('ActionMailer::Base.deliveries.size', 0) do
        post :save, :user => { :email => email, :email_confirmation => email, :display_name => display_name, :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest"}
      end
    end
    assert_response :success                                                                       
    assert_template 'new'
    assert_select "div#errorExplanation"
    assert_select "table#signupForm > tr > td > div[class=field_with_errors] > input#user_email"
  end
    
  def test_user_create_submit_duplicate_name
    email = "new_tester@example.com"
    display_name = users(:public_user).display_name
    assert_difference('User.count', 0) do
      assert_difference('ActionMailer::Base.deliveries.size', 0) do
        post :save, :user => { :email => email, :email_confirmation => email, :display_name => display_name, :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest"}
      end
    end
    assert_response :success                                                                       
    assert_template 'new'
    assert_select "div#errorExplanation"
    assert_select "table#signupForm > tr > td > div[class=field_with_errors] > input#user_display_name"
  end
  
  def test_user_create_submit_duplicate_name_uppercase
    email = "new_tester@example.com"
    display_name = users(:public_user).display_name.upcase
    assert_difference('User.count', 0) do
      assert_difference('ActionMailer::Base.deliveries.size', 0) do
        post :save, :user => { :email => email, :email_confirmation => email, :display_name => display_name, :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest"}
      end
    end
    assert_response :success                                                                       
    assert_template 'new'
    assert_select "div#errorExplanation"
    assert_select "table#signupForm > tr > td > div[class=field_with_errors] > input#user_display_name"
  end

  def test_user_lost_password
    # Test fetching the lost password page
    get :lost_password
    assert_response :success
    assert_template :lost_password
    assert_select "div#notice", false

    # Test resetting using the address as recorded for a user that has an
    # address which is duplicated in a different case by another user
    assert_difference('ActionMailer::Base.deliveries.size', 1) do
      post :lost_password, :user => { :email => users(:normal_user).email }
    end
    assert_response :redirect
    assert_redirected_to :action => :login
    assert_match /^Sorry you lost it/, flash[:notice]
    assert_equal users(:normal_user).email, ActionMailer::Base.deliveries.last.to[0]

    # Test resetting using an address that matches a different user
    # that has the same address in a different case
    assert_difference('ActionMailer::Base.deliveries.size', 1) do
      post :lost_password, :user => { :email => users(:normal_user).email.upcase }
    end
    assert_response :redirect
    assert_redirected_to :action => :login
    assert_match /^Sorry you lost it/, flash[:notice]
    assert_equal users(:uppercase_user).email, ActionMailer::Base.deliveries.last.to[0]

    # Test resetting using an address that is a case insensitive match
    # for more than one user but not an exact match for either
    assert_difference('ActionMailer::Base.deliveries.size', 0) do
      post :lost_password, :user => { :email => users(:normal_user).email.titlecase }
    end
    assert_response :success
    assert_template :lost_password
    assert_select "div#error", /^Could not find that email address/

    # Test resetting using the address as recorded for a user that has an
    # address which is case insensitively unique
    assert_difference('ActionMailer::Base.deliveries.size', 1) do
      post :lost_password, :user => { :email => users(:public_user).email }
    end
    assert_response :redirect
    assert_redirected_to :action => :login
    assert_match /^Sorry you lost it/, flash[:notice]
    assert_equal users(:public_user).email, ActionMailer::Base.deliveries.last.to[0]

    # Test resetting using an address that matches a user that has the
    # same (case insensitively unique) address in a different case
    assert_difference('ActionMailer::Base.deliveries.size', 1) do
      post :lost_password, :user => { :email => users(:public_user).email.upcase }
    end
    assert_response :redirect
    assert_redirected_to :action => :login
    assert_match /^Sorry you lost it/, flash[:notice]
    assert_equal users(:public_user).email, ActionMailer::Base.deliveries.last.to[0]
  end

  def test_user_update
    # Get a user to work with - note that this user deliberately
    # conflicts with uppercase_user in the email and display name
    # fields to test that we can change other fields without any
    # validation errors being reported
    user = users(:normal_user)

    # Set the username cookie
    @request.cookies["_osm_username"] = user.display_name

    # Make sure that you are redirected to the login page when
    # you are not logged in
    get :account, { :display_name => user.display_name }
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => "login", :referer => "/user/test/account"

    # Make sure that you are redirected to the login page when
    # you are not logged in as the right user
    get :account, { :display_name => user.display_name }, { "user" => users(:public_user).id }
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => "login", :referer => "/user/test/account"

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
    assert_select "div#notice", /^User information updated successfully/
    assert_select "table#accountForm > tr > td > div#user_description_container > div#user_description_content > textarea#user_description", user.description

    # Changing name to one that exists should fail
    user.display_name = users(:public_user).display_name
    post :account, { :display_name => user.display_name, :user => user.attributes }, { "user" => user.id }
    assert_response :success
    assert_template :account
    assert_select "div#notice", false
    assert_select "div#errorExplanation"
    assert_select "table#accountForm > tr > td > div[class=field_with_errors] > input#user_display_name"

    # Changing name to one that exists should fail, regardless of case
    user.display_name = users(:public_user).display_name.upcase
    post :account, { :display_name => user.display_name, :user => user.attributes }, { "user" => user.id }
    assert_response :success
    assert_template :account
    assert_select "div#notice", false
    assert_select "div#errorExplanation"
    assert_select "table#accountForm > tr > td > div[class=field_with_errors] > input#user_display_name"

    # Changing name to one that doesn't exist should work
    user.display_name = "new tester"
    post :account, { :display_name => user.display_name, :user => user.attributes }, { "user" => user.id }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select "div#notice", /^User information updated successfully/
    assert_select "table#accountForm > tr > td > input#user_display_name[value=?]", user.display_name

    # Need to update cookies now to stay valid
    @request.cookies["_osm_username"] = user.display_name

    # Changing email to one that exists should fail
    user.new_email = users(:public_user).email
    post :account, { :display_name => user.display_name, :user => user.attributes }, { "user" => user.id }
    assert_response :success
    assert_template :account
    assert_select "div#notice", false
    assert_select "div#errorExplanation"
    assert_select "table#accountForm > tr > td > div[class=field_with_errors] > input#user_new_email"

    # Changing email to one that exists should fail, regardless of case
    user.new_email = users(:public_user).email.upcase
    post :account, { :display_name => user.display_name, :user => user.attributes }, { "user" => user.id }
    assert_response :success
    assert_template :account
    assert_select "div#notice", false
    assert_select "div#errorExplanation"
    assert_select "table#accountForm > tr > td > div[class=field_with_errors] > input#user_new_email"

    # Changing email to one that doesn't exist should work
    user.new_email = "new_tester@example.com"
    post :account, { :display_name => user.display_name, :user => user.attributes }, { "user" => user.id }
    assert_response :success
    assert_template :account
    assert_select "div#errorExplanation", false
    assert_select "div#notice", /^User information updated successfully/
    assert_select "table#accountForm > tr > td > input#user_new_email[value=?]", user.new_email
  end
  
  # Check that the user account page will display and contains some relevant
  # information for the user
  def test_view_user_account
    get :view, {:display_name => "unknown"}
    assert_response :not_found
    
    get :view, {:display_name => "test"}
    assert_response :success
  end
  
  def test_user_api_details
    get :api_details
    assert_response :unauthorized
    
    basic_authorization(users(:normal_user).email, "test")
    get :api_details
    assert_response :success
  end
end
