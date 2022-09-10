require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/username/confirm", :method => :get },
      { :controller => "confirmations", :action => "confirm", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/confirm", :method => :post },
      { :controller => "confirmations", :action => "confirm", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/confirm/resend", :method => :get },
      { :controller => "confirmations", :action => "confirm_resend", :display_name => "username" }
    )

    assert_routing(
      { :path => "/user/confirm", :method => :get },
      { :controller => "confirmations", :action => "confirm" }
    )
    assert_routing(
      { :path => "/user/confirm", :method => :post },
      { :controller => "confirmations", :action => "confirm" }
    )
    assert_routing(
      { :path => "/user/confirm-email", :method => :get },
      { :controller => "confirmations", :action => "confirm_email" }
    )
    assert_routing(
      { :path => "/user/confirm-email", :method => :post },
      { :controller => "confirmations", :action => "confirm_email" }
    )
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
    assert_redirected_to login_path
    assert_match(/already been confirmed/, flash[:error])
  end

  def test_confirm_deleted
    user = build(:user, :pending)
    stub_gravatar_request(user.email)
    post user_new_path, :params => { :user => user.attributes }
    post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }
    confirm_string = User.find_by(:email => user.email).tokens.create.token

    User.find_by(:display_name => user.display_name).hide!

    # Get the confirmation page
    get user_confirm_path, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_response :redirect
    assert_redirected_to root_path

    # Confirm the user
    post user_confirm_path, :params => { :display_name => user.display_name, :confirm_string => confirm_string }
    assert_response :not_found
    assert_template :no_such_user
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
    assert_equal("confirmations/resend_success_flash", flash[:notice][:partial])
    assert_equal({ :email => user.email, :sender => Settings.email_from }, flash[:notice][:locals])

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

  def test_confirm_resend_deleted
    user = build(:user, :pending)
    post user_new_path, :params => { :user => user.attributes }
    post user_save_path, :params => { :read_ct => 1, :read_tou => 1 }

    User.find_by(:display_name => user.display_name).hide!

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
    assert_redirected_to edit_account_path
    assert_match(/Confirmed your change of email address/, flash[:notice])
  end

  def test_confirm_email_already_confirmed
    user = create(:user)
    confirm_string = user.tokens.create.token

    post user_confirm_email_path, :params => { :confirm_string => confirm_string }
    assert_response :redirect
    assert_redirected_to edit_account_path
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
    assert_redirected_to edit_account_path
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
    assert_redirected_to edit_account_path
    assert_match(/Confirmed your change of email address/, flash[:notice])
    # gravatar use should now be disabled
    assert_not User.find(user.id).image_use_gravatar
  end
end
