require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/forgot-password", :method => :get },
      { :controller => "passwords", :action => "lost_password" }
    )
    assert_routing(
      { :path => "/user/forgot-password", :method => :post },
      { :controller => "passwords", :action => "lost_password" }
    )
    assert_routing(
      { :path => "/user/reset-password", :method => :get },
      { :controller => "passwords", :action => "reset_password" }
    )
    assert_routing(
      { :path => "/user/reset-password", :method => :post },
      { :controller => "passwords", :action => "reset_password" }
    )
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

    # Resetting with GET should fail
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        get user_forgot_password_path, :params => { :email => user.email }
      end
    end
    assert_response :success
    assert_template :lost_password

    # Resetting with POST should work
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post user_forgot_password_path, :params => { :email => user.email }
      end
    end
    assert_response :redirect
    assert_redirected_to login_path
    assert_match(/^Sorry you lost it/, flash[:notice])
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal user.email, email.to.first
    ActionMailer::Base.deliveries.clear

    # Test resetting using an address that matches a different user
    # that has the same address in a different case
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post user_forgot_password_path, :params => { :email => user.email.upcase }
      end
    end
    assert_response :redirect
    assert_redirected_to login_path
    assert_match(/^Sorry you lost it/, flash[:notice])
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal uppercase_user.email, email.to.first
    ActionMailer::Base.deliveries.clear

    # Test resetting using an address that is a case insensitive match
    # for more than one user but not an exact match for either
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        post user_forgot_password_path, :params => { :email => user.email.titlecase }
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
        post user_forgot_password_path, :params => { :email => third_user.email }
      end
    end
    assert_response :redirect
    assert_redirected_to login_path
    assert_match(/^Sorry you lost it/, flash[:notice])
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal third_user.email, email.to.first
    ActionMailer::Base.deliveries.clear

    # Test resetting using an address that matches a user that has the
    # same (case insensitively unique) address in a different case
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post user_forgot_password_path, :params => { :email => third_user.email.upcase }
      end
    end
    assert_response :redirect
    assert_redirected_to login_path
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
    assert_select "div.invalid-feedback"

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
end
