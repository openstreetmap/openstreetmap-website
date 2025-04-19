require "test_helper"
class UsersControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_recognizes(
      { :controller => "confirmations", :action => "show", :display_name => "username" },
      { :path => "/user/username/confirm", :method => :get }
    )
    assert_routing(
      { :path => "/user/confirm-email", :method => :get },
      { :controller => "confirmations", :action => "show" }
    )
    assert_recognizes(
      { :controller => "confirmations", :action => "show", :display_name => "username" },
      { :path => "/user/username/confirmations", :method => :get }
    )
    assert_routing(
      { :path => "/user/username/confirmations", :method => :post },
      { :controller => "confirmations", :action => "create", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/confirmations/new", :method => :get },
      { :controller => "confirmations", :action => "new", :display_name => "username" }
    )
  end

  def test_confirm_get
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post users_path, :params => { :user => user.attributes }
    confirm_string = User.find_by(:email => user.email).generate_token_for(:account_confirmation)

    get confirmations_path(user.display_name), :params => { :confirm_string => confirm_string, :referer => welcome_path }
    assert_redirected_to welcome_path
  end

  def test_confirm_get_already_confirmed
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post users_path, :params => { :user => user.attributes }
    confirm_string = User.find_by(:email => user.email).generate_token_for(:account_confirmation)

    get confirmations_path(user.display_name), :params => { :confirm_string => confirm_string, :referer => welcome_path }
    assert_redirected_to welcome_path

    get confirmations_path(user.display_name), :params => { :confirm_string => confirm_string, :referer => welcome_path }
    assert_redirected_to root_path
  end

  def test_confirm_success_no_token_no_referer
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post users_path, :params => { :user => user.attributes }
    confirm_string = User.find_by(:email => user.email).generate_token_for(:account_confirmation)

    post logout_path

    get confirmations_path(user.display_name), :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_redirected_to root_path
    assert_match(/Confirmed your email address/, flash[:notice])
  end

  def test_confirm_success_good_token_no_referer
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post users_path, :params => { :user => user.attributes }
    confirm_string = User.find_by(:email => user.email).generate_token_for(:account_confirmation)

    get confirmations_path(user.display_name), :params => { :confirm_string => confirm_string }
    assert_redirected_to root_path
  end

  def test_confirm_success_bad_token_no_referer
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post users_path, :params => { :user => user.attributes }
    confirm_string = User.find_by(:email => user.email).generate_token_for(:account_confirmation)

    post logout_path
    session_for(create(:user))

    get confirmations_path(user.display_name), :params => { :confirm_string => confirm_string }
    assert_redirected_to root_path
    assert_match(/Confirmed your email address/, flash[:notice])
  end

  def test_confirm_success_no_token_with_referer
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post users_path, :params => { :user => user.attributes }
    confirm_string = User.find_by(:email => user.email).generate_token_for(:account_confirmation)

    post logout_path

    get confirmations_path(user.display_name), :params => { :confirm_string => confirm_string, :referer => new_diary_entry_path }
    assert_redirected_to new_diary_entry_path
    assert_match(/Confirmed your email address/, flash[:notice])
  end

  def test_confirm_success_good_token_with_referer
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post users_path, :params => { :user => user.attributes }
    confirm_string = User.find_by(:email => user.email).generate_token_for(:new_user)

    get confirmations_path(user.display_name), :params => { :confirm_string => confirm_string, :referer => new_diary_entry_path }
    assert_redirected_to new_diary_entry_path
  end

  def test_confirm_success_bad_token_with_referer
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post users_path, :params => { :user => user.attributes }
    confirm_string = User.find_by(:email => user.email).generate_token_for(:new_user)
    post logout_path
    session_for(create(:user))

    get confirmations_path(user.display_name), :params => { :confirm_string => confirm_string, :referer => new_diary_entry_path }
    assert_redirected_to new_diary_entry_path
    assert_match(/Confirmed your email address/, flash[:notice])
  end

  def test_confirm_expired_token
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post users_path, :params => { :user => user.attributes }
    confirm_string = User.find_by(:email => user.email).generate_token_for(:new_user)

    travel 2.weeks do
      get confirmations_path(user.display_name), :params => { :confirm_string => confirm_string }
    end
    assert_redirected_to root_path
    assert_match(/confirmation code has expired/, flash[:error])
  end

  def test_confirm_already_confirmed
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post users_path, :params => { :user => user.attributes }
    confirm_string = User.find_by(:email => user.email).generate_token_for(:new_user)

    get confirmations_path(user.display_name), :params => { :confirm_string => confirm_string, :referer => new_diary_entry_path }
    assert_redirected_to new_diary_entry_path

    post logout_path

    confirm_string = User.find_by(:email => user.email).generate_token_for(:new_user)
    get confirmations_path(user.display_name), :params => { :confirm_string => confirm_string, :referer => new_diary_entry_path }
    assert_redirected_to root_path
    assert_match(/already been confirmed/, flash[:error])
  end

  def test_confirm_deleted
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post users_path, :params => { :user => user.attributes }
    confirm_string = User.find_by(:email => user.email).generate_token_for(:new_user)
    User.find_by(:display_name => user.display_name).hide!

    # Get the confirmation page
    get new_confirmations_path(user.display_name), :params => { :confirm_string => confirm_string }
    assert_redirected_to root_path

    # Confirm the user
    get confirmations_path(user.display_name), :params => { :confirm_string => confirm_string }
    assert_response :not_found
    assert_template :no_such_user
  end
  def test_confirm_resend_success
    user = build(:user, :pending)
    post users_path, :params => { :user => user.attributes }

    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post confirmations_path(user)
      end
    end

    assert_redirected_to new_confirmations_path
    assert_equal("confirmations/resend_success_flash", flash[:notice][:partial])
    assert_equal({ :email => user.email, :sender => Settings.email_from }, flash[:notice][:locals])
    email = ActionMailer::Base.deliveries.last
    assert_equal user.email, email.to.first
  end
  def test_confirm_resend_deleted
    user = build(:user, :pending)
    post users_path, :params => { :user => user.attributes }
    User.find_by(:display_name => user.display_name).hide!

    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        post confirmations_path(user)
      end
    end

    assert_redirected_to new_confirmations_path
    assert_match "User #{user.display_name} not found.", flash[:error]
  end
  def test_confirm_resend_unknown_user
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        post confirmations_path(:display_name => "No Such User")
      end
    end

    assert_redirected_to new_confirmations_path
    assert_match "User No Such User not found.", flash[:error]
  end

  def test_confirm_email_success
    user = create(:user, :new_email => "test-new@example.com")
    stub_gravatar_request(user.new_email)
    confirm_string = user.generate_token_for(:new_email)

    get user_confirm_email_path, :params => { :confirm_string => confirm_string, :referer => account_path }
    follow_redirect!
    assert_redirected_to account_path
    assert_match(/Confirmed your email address/, flash[:notice])
  end

  def test_confirm_email_already_confirmed
    user = create(:user)
    confirm_string = user.generate_token_for(:new_email)

    get user_confirm_email_path, :params => { :confirm_string => confirm_string }
    follow_redirect!
    assert_redirected_to root_path
    assert_match(/already been confirmed/, flash[:error])
  end

  def test_confirm_email_bad_token
    get user_confirm_email_path, :params => { :confirm_string => "XXXXX" }
    follow_redirect!
    assert_redirected_to root_path
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
    confirm_string = user.generate_token_for(:new_email)
    # precondition gravatar should be turned off
    assert_not user.image_use_gravatar
    get user_confirm_email_path, :params => { :confirm_string => confirm_string, :referer => account_path }
    follow_redirect!
    assert_redirected_to account_path
    assert_match(/Confirmed your email address/, flash[:notice])
    # gravatar use should now be enabled
    assert User.find(user.id).image_use_gravatar
  end
  def test_gravatar_auto_disable
    # switch to email without a gravatar
    user = create(:user, :new_email => "test-new@example.com", :image_use_gravatar => true)
    stub_gravatar_request(user.new_email, 404)
    confirm_string = user.generate_token_for(:new_email)
    # precondition gravatar should be turned on
    assert user.image_use_gravatar
    get user_confirm_email_path, :params => { :confirm_string => confirm_string, :referer => account_path }
    follow_redirect!
    assert_redirected_to account_path
    assert_match(/Confirmed your email address/, flash[:notice])
    # gravatar use should now be disabled
    assert_not User.find(user.id).image_use_gravatar
  end
end