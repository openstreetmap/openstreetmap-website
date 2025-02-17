require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/account", :method => :get },
      { :controller => "accounts", :action => "show" }
    )
    assert_routing(
      { :path => "/account", :method => :put },
      { :controller => "accounts", :action => "update" }
    )
    assert_routing(
      { :path => "/account", :method => :delete },
      { :controller => "accounts", :action => "destroy" }
    )

    get "/account/edit"
    assert_redirected_to "/account"
  end

  def test_show_and_update
    # Get a user to work with - note that this user deliberately
    # conflicts with uppercase_user in the email and display name
    # fields to test that we can change other fields without any
    # validation errors being reported
    user = create(:user, :languages => [])
    _uppercase_user = build(:user, :email => user.email.upcase, :display_name => user.display_name.upcase).tap { |u| u.save(:validate => false) }

    # Make sure that you are redirected to the login page when
    # you are not logged in
    get account_path
    assert_redirected_to login_path(:referer => account_path)

    # Make sure we get the page when we are logged in as the right user
    session_for(user)
    get account_path
    assert_response :success
    assert_template :show
    assert_select "form#accountForm" do |form|
      assert_equal "post", form.attr("method").to_s
      assert_select "input[name='_method']", true
      assert_equal "/account", form.attr("action").to_s
    end

    # Updating the description using GET should fail
    user.description = "new description"
    user.preferred_editor = "default"
    get account_path, :params => { :user => user.attributes }
    assert_response :success
    assert_template :show
    assert_not_equal user.description, User.find(user.id).description

    # Adding external authentication should redirect to the auth provider
    patch account_path, :params => { :user => user.attributes.merge(:auth_provider => "google") }
    assert_redirected_to auth_path(:provider => "google", :origin => "/account")
    follow_redirect!
    assert_redirected_to %r{^https://accounts.google.com/o/oauth2/auth\?.*}

    # Changing name to one that exists should fail
    new_attributes = user.attributes.dup.merge(:display_name => create(:user).display_name)
    patch account_path, :params => { :user => new_attributes }
    assert_response :success
    assert_template :show
    assert_select ".alert-success", false
    assert_select "form#accountForm > div > input.is-invalid#user_display_name"

    # Changing name to one that exists should fail, regardless of case
    new_attributes = user.attributes.dup.merge(:display_name => create(:user).display_name.upcase)
    patch account_path, :params => { :user => new_attributes }
    assert_response :success
    assert_template :show
    assert_select ".alert-success", false
    assert_select "form#accountForm > div > input.is-invalid#user_display_name"

    # Changing name to one that doesn't exist should work
    new_attributes = user.attributes.dup.merge(:display_name => "new tester")
    patch account_path, :params => { :user => new_attributes }
    assert_redirected_to account_path
    follow_redirect!
    assert_response :success
    assert_template :show
    assert_select ".alert-success", /^User information updated successfully/
    assert_select "form#accountForm > div > input#user_display_name[value=?]", "new tester"

    # Record the change of name
    user.display_name = "new tester"

    # Changing email to one that exists should fail
    user.new_email = create(:user).email
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        patch account_path, :params => { :user => user.attributes }
      end
    end
    assert_response :success
    assert_template :show
    assert_select ".alert-success", false
    assert_select "form#accountForm > div > input.is-invalid#user_new_email"

    # Changing email to one that exists should fail, regardless of case
    user.new_email = create(:user).email.upcase
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        patch account_path, :params => { :user => user.attributes }
      end
    end
    assert_response :success
    assert_template :show
    assert_select ".alert-success", false
    assert_select "form#accountForm > div > input.is-invalid#user_new_email"

    # Changing email to one that doesn't exist should work
    user.new_email = "new_tester@example.com"
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        patch account_path, :params => { :user => user.attributes }
      end
    end
    assert_redirected_to account_path
    follow_redirect!
    assert_response :success
    assert_template :show
    assert_select ".alert-success", /^User information updated successfully/
    assert_select "form#accountForm > div > input#user_new_email[value=?]", user.new_email
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal user.new_email, email.to.first
  end

  def test_show_private_account
    user = create(:user, :data_public => false)

    # Make sure that you are redirected to the login page when
    # you are not logged in
    get account_path
    assert_redirected_to login_path(:referer => account_path)

    # Make sure we get the page when we are logged in as the right user
    session_for(user)
    get account_path
    assert_response :success
    assert_template :show
    assert_select "form#accountForm" do |form|
      assert_equal "post", form.attr("method").to_s
      assert_select "input[name='_method']", true
      assert_equal "/account", form.attr("action").to_s
    end

    # Make sure we have a button to "go public"
    assert_select "form.button_to[action='/user/go_public']", true
  end

  def test_destroy_allowed
    user = create(:user)
    session_for(user)

    delete account_path
    assert_response :redirect
  end

  def test_destroy_not_allowed
    with_user_account_deletion_delay(24) do
      user = create(:user)
      create(:changeset, :user => user, :created_at => Time.now.utc)
      session_for(user)

      delete account_path
      assert_response :bad_request
    end
  end
end
