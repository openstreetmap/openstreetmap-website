require "test_helper"

class UserCreationTest < ActionDispatch::IntegrationTest
  def setup
    OmniAuth.config.test_mode = true

    stub_request(:get, /.*gravatar.com.*d=404/).to_return(:status => 404)
  end

  def teardown
    OmniAuth.config.mock_auth[:openid] = nil
    OmniAuth.config.mock_auth[:google] = nil
    OmniAuth.config.mock_auth[:facebook] = nil
    OmniAuth.config.mock_auth[:microsoft] = nil
    OmniAuth.config.mock_auth[:github] = nil
    OmniAuth.config.mock_auth[:wikipedia] = nil
    OmniAuth.config.test_mode = false
  end

  def test_create_user_form
    get "/user/new"
    follow_redirect!
    assert_response :success
    assert_template "users/new"
  end

  def test_user_create_submit_duplicate_email
    dup_email = create(:user).email
    display_name = "new_tester"
    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post "/user",
               :params => { :user => { :email => dup_email,
                                       :display_name => display_name,
                                       :pass_crypt => "testtest",
                                       :pass_crypt_confirmation => "testtest" } }
        end
      end
    end
    assert_response :success
    assert_template "users/new"
    assert_select "form"
    assert_select "form > div > input.is-invalid#user_email"
  end

  def test_user_create_association_submit_duplicate_email
    dup_email = create(:user).email
    display_name = "new_tester"
    assert_difference("User.count", 0) do
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        perform_enqueued_jobs do
          post "/user",
               :params => { :user => { :email => dup_email,
                                       :display_name => display_name,
                                       :pass_crypt => "testtest",
                                       :pass_crypt_confirmation => "testtest",
                                       :auth_provider => "google",
                                       :auth_uid => "123454321" } }
        end
      end
    end
    assert_response :success
    assert_template "users/new"
    assert_select "form"
    assert_select "form > div > input.is-invalid#user_email"
  end

  def test_user_create_submit_duplicate_username
    dup_display_name = create(:user).display_name
    email = "new_tester"
    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post "/user",
               :params => { :user => { :email => email,
                                       :display_name => dup_display_name,
                                       :pass_crypt => "testtest",
                                       :pass_crypt_confirmation => "testtest" } }
        end
      end
    end
    assert_response :success
    assert_template "users/new"
    assert_select "form > div > input.is-invalid#user_display_name"
  end

  def test_user_create_submit_mismatched_passwords
    email = "newtester@osm.org"
    display_name = "new_tester"
    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post "/user",
               :params => { :user => { :email => email,
                                       :display_name => display_name,
                                       :pass_crypt => "testtest",
                                       :pass_crypt_confirmation => "blahblah" } }
        end
      end
    end
    assert_response :success
    assert_template "users/new"
    assert_select "form > div > div > div > input.is-invalid#user_pass_crypt_confirmation"
  end

  def test_user_create_association_submit_duplicate_username
    dup_display_name = create(:user).display_name
    email = "new_tester"
    assert_difference("User.count", 0) do
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        perform_enqueued_jobs do
          post "/user",
               :params => { :user => { :email => email,
                                       :display_name => dup_display_name,
                                       :auth_provider => "google",
                                       :auth_uid => "123454321" } }
        end
      end
    end
    assert_response :success
    assert_template "users/new"
    assert_select "form > div > input.is-invalid#user_display_name"
  end

  def test_user_create_success
    new_email = "newtester@osm.org"
    display_name = "new_tester"

    assert_difference("User.count", 1) do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post "/user",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :pass_crypt => "testtest",
                                       :pass_crypt_confirmation => "testtest" } }
          assert_redirected_to :controller => :confirmations, :action => :confirm, :display_name => display_name
          follow_redirect!
        end
      end
    end

    assert_response :success
    assert_template "confirmations/confirm"

    user = User.find_by(:email => "newtester@osm.org")
    assert_not_nil user
    assert_not_predicate user, :active?

    register_email = ActionMailer::Base.deliveries.first
    assert_equal register_email.to.first, new_email
    found_confirmation_url = register_email.parts.first.parts.first.to_s =~ %r{\shttp://test.host(/\S+)\s}
    assert found_confirmation_url
    confirmation_url = Regexp.last_match(1)

    post confirmation_url

    assert_redirected_to welcome_path

    user.reload
    assert_predicate user, :active?

    assert_equal user, User.authenticate(:username => new_email, :password => "testtest")
  end

  # Check that the user can successfully recover their password
  # def test_lost_password_recovery_success
  #   Open the lost password form
  #   Submit the lost password form
  #   Check the e-mail
  #   Submit the reset password token
  #   Check that the password has changed, and the user can login
  # end

  def test_user_create_redirect
    new_email = "redirect_tester@osm.org"
    display_name = "redirect_tester"
    password = "testtest"
    # nothing special about this page, just need a protected page to redirect back to.
    referer = "/traces/mine"
    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post "/user",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :pass_crypt => password,
                                       :pass_crypt_confirmation => password },
                            :referer => referer }
          assert_response(:redirect)
          assert_redirected_to :controller => :confirmations, :action => :confirm, :display_name => display_name
          follow_redirect!
        end
      end
    end

    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first

    assert_equal register_email.to.first, new_email
    # Check that the confirm account url is correct
    confirm_regex = Regexp.new("confirm_string=([a-zA-Z0-9%_-]*)")
    email_text_parts(register_email).each do |part|
      assert_match confirm_regex, part.body.to_s
    end
    confirm_string = CGI.unescape(email_text_parts(register_email).first.body.match(confirm_regex)[1])

    # Check the page
    assert_response :success
    assert_template "confirmations/confirm"

    # Go to the confirmation page
    get "/user/#{display_name}/confirm", :params => { :referer => "/welcome", :confirm_string => confirm_string }
    assert_response :success
    assert_template "confirmations/confirm"

    post "/user/#{display_name}/confirm", :params => { :referer => "/welcome", :confirm_string => confirm_string }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "site/welcome"
  end

  def test_user_create_openid_success
    new_email = "newtester-openid@osm.org"
    display_name = "new_tester-openid"
    openid_url = "http://localhost:1000/new.tester"
    auth_uid = "http://localhost:1123/new.tester"

    OmniAuth.config.add_mock(:openid,
                             :uid => auth_uid,
                             :info => { :email => new_email, :name => display_name })

    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post auth_path(:provider => "openid", :openid_url => openid_url, :origin => "/user/new")
          assert_redirected_to auth_success_path(:provider => "openid", :openid_url => openid_url, :origin => "/user/new")
          follow_redirect!
          assert_redirected_to :controller => :users, :action => "new", :nickname => display_name, :email => new_email,
                               :auth_provider => "openid", :auth_uid => auth_uid
          follow_redirect!
          post "/user",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "openid",
                                       :auth_uid => auth_uid } }
        end
      end
    end

    # Check the page
    assert_redirected_to :controller => :confirmations, :action => :confirm, :display_name => display_name
  end

  def test_user_create_openid_duplicate_email
    dup_user = create(:user)
    display_name = "new_tester-openid"
    auth_uid = "123454321"

    OmniAuth.config.add_mock(:openid,
                             :uid => auth_uid,
                             :info => { :email => dup_user.email, :name => display_name })

    post auth_path(:provider => "openid", :origin => "/user/new")
    assert_redirected_to auth_success_path(:provider => "openid", :origin => "/user/new")
    follow_redirect!
    assert_redirected_to :controller => :users, :action => "new", :nickname => display_name, :email => dup_user.email,
                         :auth_provider => "openid", :auth_uid => auth_uid
    follow_redirect!

    assert_response :success
    assert_template "users/new"
    assert_select "form > div > input.is-invalid#user_email"
  end

  def test_user_create_openid_failure
    OmniAuth.config.mock_auth[:openid] = :connection_failed

    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post auth_path(:provider => "openid", :openid_url => "http://localhost:1123/new.tester", :origin => "/user/new")
          follow_redirect!
          assert_redirected_to auth_failure_path(:strategy => "openid", :message => "connection_failed", :origin => "/user/new")
          follow_redirect!
          assert_redirected_to "/user/new"
        end
      end
    end
  end

  def test_user_create_openid_redirect
    openid_url = "http://localhost:1000/new.tester"
    auth_uid = "http://localhost:1123/new.tester"
    new_email = "redirect_tester_openid@osm.org"
    display_name = "redirect_tester_openid"

    OmniAuth.config.add_mock(:openid,
                             :uid => auth_uid,
                             :info => { :email => new_email, :name => display_name })

    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post auth_path(:provider => "openid", :openid_url => openid_url, :origin => "/user/new")
          assert_redirected_to auth_success_path(:provider => "openid", :openid_url => openid_url, :origin => "/user/new")
          follow_redirect!
          assert_redirected_to :controller => :users, :action => "new", :nickname => display_name, :email => new_email,
                               :auth_provider => "openid", :auth_uid => auth_uid
          follow_redirect!
          post "/user",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "openid",
                                       :auth_uid => auth_uid } }
          follow_redirect!
        end
      end
    end

    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first

    assert_equal register_email.to.first, new_email
    # Check that the confirm account url is correct
    confirm_regex = Regexp.new("confirm_string=([a-zA-Z0-9%_-]*)")
    email_text_parts(register_email).each do |part|
      assert_match confirm_regex, part.body.to_s
    end
    confirm_string = CGI.unescape(email_text_parts(register_email).first.body.match(confirm_regex)[1])

    # Check the page
    assert_response :success
    assert_template "confirmations/confirm"

    # Go to the confirmation page
    get "/user/#{display_name}/confirm", :params => { :referer => "/welcome", :confirm_string => confirm_string }
    assert_response :success
    assert_template "confirmations/confirm"

    post "/user/#{display_name}/confirm", :params => { :referer => "/welcome", :confirm_string => confirm_string }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "site/welcome"
  end

  def test_user_create_google_success
    new_email = "newtester-google@osm.org"
    email_hmac = UsersController.message_hmac(new_email)
    display_name = "new_tester-google"
    auth_uid = "123454321"

    OmniAuth.config.add_mock(:google,
                             :uid => auth_uid,
                             :extra => { :id_info => { :openid_id => "http://localhost:1123/new.tester" } },
                             :info => { :email => new_email, :name => display_name })

    assert_difference("User.count") do
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        perform_enqueued_jobs do
          post auth_path(:provider => "google", :origin => "/user/new")
          assert_redirected_to auth_success_path(:provider => "google")
          follow_redirect!
          assert_redirected_to :controller => :users, :action => "new", :nickname => display_name,
                               :email => new_email, :email_hmac => email_hmac,
                               :auth_provider => "google", :auth_uid => auth_uid
          follow_redirect!

          post "/user",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "google",
                                       :auth_uid => auth_uid },
                            :email_hmac => email_hmac }
          assert_redirected_to welcome_path
          follow_redirect!
        end
      end
    end

    # Check the page
    assert_response :success
    assert_template "site/welcome"
  end

  def test_user_create_google_duplicate_email
    dup_user = create(:user)
    display_name = "new_tester-google"
    auth_uid = "123454321"

    OmniAuth.config.add_mock(:google,
                             :uid => auth_uid,
                             :extra => { :id_info => { :openid_id => "http://localhost:1123/new.tester" } },
                             :info => { :email => dup_user.email, :name => display_name })

    post auth_path(:provider => "google", :origin => "/user/new")
    assert_redirected_to auth_success_path(:provider => "google")
    follow_redirect!
    assert_redirected_to :controller => :users, :action => "new", :nickname => display_name, :email => dup_user.email,
                         :email_hmac => UsersController.message_hmac(dup_user.email),
                         :auth_provider => "google", :auth_uid => auth_uid
    follow_redirect!

    assert_response :success
    assert_template "users/new"
    assert_select "form > div > input.is-invalid#user_email"
  end

  def test_user_create_google_failure
    OmniAuth.config.mock_auth[:google] = :connection_failed

    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post auth_path(:provider => "google", :origin => "/user/new")
          assert_response :redirect
          follow_redirect!
          assert_redirected_to auth_failure_path(:strategy => "google", :message => "connection_failed", :origin => "/user/new")
          follow_redirect!
          assert_redirected_to "/user/new"
        end
      end
    end
  end

  def test_user_create_google_redirect
    orig_email = "redirect_tester_google_orig@google.com"
    email_hmac = UsersController.message_hmac(orig_email)
    new_email =  "redirect_tester_google@osm.org"
    display_name = "redirect_tester_google"
    auth_uid = "123454321"

    OmniAuth.config.add_mock(:google,
                             :uid => auth_uid,
                             :extra => { :id_info => { :openid_id => "http://localhost:1123/new.tester" } },
                             :info => { :email => orig_email, :name => display_name })

    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post auth_path(:provider => "google", :origin => "/user/new")
          assert_redirected_to auth_success_path(:provider => "google")
          follow_redirect!
          assert_redirected_to :controller => :users, :action => "new", :nickname => display_name,
                               :email => orig_email, :email_hmac => email_hmac,
                               :auth_provider => "google", :auth_uid => auth_uid
          follow_redirect!
          post "/user",
               :params => { :user => { :email => new_email,
                                       :email_hmac => email_hmac,
                                       :display_name => display_name,
                                       :auth_provider => "google",
                                       :auth_uid => auth_uid } }
          assert_response :redirect
          follow_redirect!
        end
      end
    end

    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first

    assert_equal register_email.to.first, new_email
    # Check that the confirm account url is correct
    confirm_regex = Regexp.new("confirm_string=([a-zA-Z0-9%_-]*)")
    email_text_parts(register_email).each do |part|
      assert_match confirm_regex, part.body.to_s
    end
    confirm_string = CGI.unescape(email_text_parts(register_email).first.body.match(confirm_regex)[1])

    # Check the page
    assert_response :success
    assert_template "confirmations/confirm"

    # Go to the confirmation page
    get "/user/#{display_name}/confirm", :params => { :referer => "/welcome", :confirm_string => confirm_string }
    assert_response :success
    assert_template "confirmations/confirm"

    post "/user/#{display_name}/confirm", :params => { :referer => "/welcome", :confirm_string => confirm_string }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "site/welcome"
  end

  def test_user_create_facebook_success
    new_email = "newtester-facebook@osm.org"
    email_hmac = UsersController.message_hmac(new_email)
    display_name = "new_tester-facebook"
    auth_uid = "123454321"

    OmniAuth.config.add_mock(:facebook,
                             :uid => auth_uid,
                             :info => { "email" => new_email, :name => display_name })

    assert_difference("User.count") do
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        perform_enqueued_jobs do
          post auth_path(:provider => "facebook", :origin => "/user/new")
          assert_redirected_to auth_success_path(:provider => "facebook")
          follow_redirect!
          assert_redirected_to :controller => :users, :action => "new", :nickname => display_name,
                               :email => new_email, :email_hmac => email_hmac,
                               :auth_provider => "facebook", :auth_uid => auth_uid
          follow_redirect!

          post "/user",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "facebook",
                                       :auth_uid => auth_uid },
                            :email_hmac => email_hmac }
          assert_redirected_to welcome_path
          follow_redirect!
        end
      end
    end

    # Check the page
    assert_response :success
    assert_template "site/welcome"
  end

  def test_user_create_facebook_duplicate_email
    dup_user = create(:user)
    display_name = "new_tester-facebook"
    auth_uid = "123454321"

    OmniAuth.config.add_mock(:facebook,
                             :uid => auth_uid,
                             :info => { :email => dup_user.email, :name => display_name })

    post auth_path(:provider => "facebook", :origin => "/user/new")
    assert_redirected_to auth_success_path(:provider => "facebook")
    follow_redirect!
    assert_redirected_to :controller => :users, :action => "new", :nickname => display_name, :email => dup_user.email,
                         :email_hmac => UsersController.message_hmac(dup_user.email),
                         :auth_provider => "facebook", :auth_uid => auth_uid
    follow_redirect!

    assert_response :success
    assert_template "users/new"
    assert_select "form > div > input.is-invalid#user_email"
  end

  def test_user_create_facebook_failure
    OmniAuth.config.mock_auth[:facebook] = :connection_failed

    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post auth_path(:provider => "facebook", :origin => "/user/new")
          assert_response :redirect
          follow_redirect!
          assert_redirected_to auth_failure_path(:strategy => "facebook", :message => "connection_failed", :origin => "/user/new")
          follow_redirect!
          assert_redirected_to "/user/new"
        end
      end
    end
  end

  def test_user_create_facebook_redirect
    orig_email = "redirect_tester_facebook_orig@osm.org"
    email_hmac = UsersController.message_hmac(orig_email)
    new_email = "redirect_tester_facebook@osm.org"
    display_name = "redirect_tester_facebook"
    auth_uid = "123454321"

    OmniAuth.config.add_mock(:facebook,
                             :uid => auth_uid,
                             :info => { :email => orig_email, :name => display_name })

    # nothing special about this page, just need a protected page to redirect back to.
    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post auth_path(:provider => "facebook", :origin => "/user/new")
          assert_redirected_to auth_success_path(:provider => "facebook")
          follow_redirect!
          assert_redirected_to :controller => :users, :action => "new", :nickname => display_name,
                               :email => orig_email, :email_hmac => email_hmac,
                               :auth_provider => "facebook", :auth_uid => auth_uid
          follow_redirect!

          post "/user",
               :params => { :user => { :email => new_email,
                                       :email_hmac => email_hmac,
                                       :display_name => display_name,
                                       :auth_provider => "facebook",
                                       :auth_uid => auth_uid } }
          assert_response :redirect
          follow_redirect!
        end
      end
    end

    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first

    assert_equal register_email.to.first, new_email
    # Check that the confirm account url is correct
    confirm_regex = Regexp.new("confirm_string=([a-zA-Z0-9%_-]*)")
    email_text_parts(register_email).each do |part|
      assert_match confirm_regex, part.body.to_s
    end
    confirm_string = CGI.unescape(email_text_parts(register_email).first.body.match(confirm_regex)[1])

    # Check the page
    assert_response :success
    assert_template "confirmations/confirm"

    # Go to the confirmation page
    get "/user/#{display_name}/confirm", :params => { :referer => "/welcome", :confirm_string => confirm_string }
    assert_response :success
    assert_template "confirmations/confirm"

    post "/user/#{display_name}/confirm", :params => { :referer => "/welcome", :confirm_string => confirm_string }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "site/welcome"
  end

  def test_user_create_microsoft_success
    new_email = "newtester-microsoft@osm.org"
    email_hmac = UsersController.message_hmac(new_email)
    display_name = "new_tester-microsoft"
    auth_uid = "123454321"

    OmniAuth.config.add_mock(:microsoft,
                             :uid => auth_uid,
                             :info => { "email" => new_email, :name => display_name })

    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post auth_path(:provider => "microsoft", :origin => "/user/new")
          assert_redirected_to auth_success_path(:provider => "microsoft")
          follow_redirect!
          assert_redirected_to :controller => :users, :action => "new", :nickname => display_name,
                               :email => new_email, :email_hmac => email_hmac,
                               :auth_provider => "microsoft", :auth_uid => auth_uid
          follow_redirect!
          post "/user",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "microsoft",
                                       :auth_uid => auth_uid },
                            :email_hmac => email_hmac }
          assert_redirected_to welcome_path
          follow_redirect!
        end
      end
    end

    # Check the page
    assert_response :success
    assert_template "site/welcome"
  end

  def test_user_create_microsoft_duplicate_email
    dup_user = create(:user)
    display_name = "new_tester-microsoft"
    auth_uid = "123454321"

    OmniAuth.config.add_mock(:microsoft,
                             :uid => auth_uid,
                             :info => { :email => dup_user.email, :name => display_name })

    post auth_path(:provider => "microsoft", :origin => "/user/new")
    assert_redirected_to auth_success_path(:provider => "microsoft")
    follow_redirect!
    assert_redirected_to :controller => :users, :action => "new", :nickname => display_name, :email => dup_user.email,
                         :email_hmac => UsersController.message_hmac(dup_user.email),
                         :auth_provider => "microsoft", :auth_uid => auth_uid
    follow_redirect!

    assert_response :success
    assert_template "users/new"
    assert_select "form > div > input.is-invalid#user_email"
  end

  def test_user_create_microsoft_failure
    OmniAuth.config.mock_auth[:microsoft] = :connection_failed

    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post auth_path(:provider => "microsoft", :origin => "/user/new")
          assert_response :redirect
          follow_redirect!
          assert_redirected_to auth_failure_path(:strategy => "microsoft", :message => "connection_failed", :origin => "/user/new")
          follow_redirect!
          assert_redirected_to "/user/new"
        end
      end
    end
  end

  def test_user_create_microsoft_redirect
    orig_email = "redirect_tester_microsoft_orig@osm.org"
    email_hmac = UsersController.message_hmac(orig_email)
    new_email = "redirect_tester_microsoft@osm.org"
    display_name = "redirect_tester_microsoft"
    auth_uid = "123454321"

    OmniAuth.config.add_mock(:microsoft,
                             :uid => auth_uid,
                             :info => { :email => orig_email, :name => display_name })

    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post auth_path(:provider => "microsoft", :origin => "/user/new")
          assert_redirected_to auth_success_path(:provider => "microsoft")
          follow_redirect!
          assert_redirected_to :controller => :users, :action => "new", :nickname => display_name,
                               :email => orig_email, :email_hmac => email_hmac,
                               :auth_provider => "microsoft", :auth_uid => auth_uid
          follow_redirect!

          post "/user",
               :params => { :user => { :email => new_email,
                                       :email_hmac => email_hmac,
                                       :display_name => display_name,
                                       :auth_provider => "microsoft",
                                       :auth_uid => auth_uid } }
          assert_response :redirect
          follow_redirect!
        end
      end
    end

    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first

    assert_equal register_email.to.first, new_email
    # Check that the confirm account url is correct
    confirm_regex = Regexp.new("confirm_string=([a-zA-Z0-9%_-]*)")
    email_text_parts(register_email).each do |part|
      assert_match confirm_regex, part.body.to_s
    end
    confirm_string = CGI.unescape(email_text_parts(register_email).first.body.match(confirm_regex)[1])

    # Check the page
    assert_response :success
    assert_template "confirmations/confirm"

    # Go to the confirmation page
    get "/user/#{display_name}/confirm", :params => { :referer => "/welcome", :confirm_string => confirm_string }
    assert_response :success
    assert_template "confirmations/confirm"

    post "/user/#{display_name}/confirm", :params => { :referer => "/welcome", :confirm_string => confirm_string }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "site/welcome"
  end

  def test_user_create_github_success
    new_email = "newtester-github@osm.org"
    email_hmac = UsersController.message_hmac(new_email)
    display_name = "new_tester-github"
    password = "testtest"
    auth_uid = "123454321"

    OmniAuth.config.add_mock(:github,
                             :uid => auth_uid,
                             :info => { "email" => new_email, :name => display_name })

    assert_difference("User.count") do
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        perform_enqueued_jobs do
          post auth_path(:provider => "github", :origin => "/user/new")
          assert_redirected_to auth_success_path(:provider => "github")
          follow_redirect!
          assert_redirected_to :controller => :users, :action => "new", :nickname => display_name,
                               :email => new_email, :email_hmac => email_hmac,
                               :auth_provider => "github", :auth_uid => auth_uid
          follow_redirect!

          post "/user",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "github",
                                       :auth_uid => "123454321",
                                       :pass_crypt => password,
                                       :pass_crypt_confirmation => password },
                            :read_ct => 1,
                            :read_tou => 1,
                            :email_hmac => email_hmac }
          assert_redirected_to welcome_path
          follow_redirect!
        end
      end
    end

    # Check the page
    assert_response :success
    assert_template "site/welcome"
  end

  def test_user_create_github_duplicate_email
    dup_user = create(:user)
    display_name = "new_tester-github"
    auth_uid = "123454321"

    OmniAuth.config.add_mock(:github,
                             :uid => auth_uid,
                             :extra => { :id_info => { :openid_id => "http://localhost:1123/new.tester" } },
                             :info => { :email => dup_user.email, :name => display_name })

    post auth_path(:provider => "github", :origin => "/user/new")
    assert_redirected_to auth_success_path(:provider => "github")
    follow_redirect!
    assert_redirected_to :controller => :users, :action => "new", :nickname => display_name,
                         :email => dup_user.email, :email_hmac => UsersController.message_hmac(dup_user.email),
                         :auth_provider => "github", :auth_uid => auth_uid
    follow_redirect!

    assert_response :success
    assert_template "users/new"
    assert_select "form > div > input.is-invalid#user_email"
  end

  def test_user_create_github_failure
    OmniAuth.config.mock_auth[:github] = :connection_failed

    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post auth_path(:provider => "github", :origin => "/user/new")
          follow_redirect!
          assert_redirected_to auth_failure_path(:strategy => "github", :message => "connection_failed", :origin => "/user/new")
          follow_redirect!
          assert_redirected_to "/user/new"
        end
      end
    end
  end

  def test_user_create_github_redirect
    orig_email = "redirect_tester_github_orig@osm.org"
    email_hmac = UsersController.message_hmac(orig_email)
    new_email = "redirect_tester_github@osm.org"
    display_name = "redirect_tester_github"
    auth_uid = "123454321"

    OmniAuth.config.add_mock(:github,
                             :uid => auth_uid,
                             :info => { :email => orig_email, :name => display_name })

    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post auth_path(:provider => "github", :origin => "/user/new")
          assert_redirected_to auth_success_path(:provider => "github")
          follow_redirect!
          assert_redirected_to :controller => :users, :action => "new", :nickname => display_name,
                               :email => orig_email, :email_hmac => email_hmac,
                               :auth_provider => "github", :auth_uid => auth_uid
          follow_redirect!
          post "/user",
               :params => { :user => { :email => new_email,
                                       :email_hmac => email_hmac,
                                       :display_name => display_name,
                                       :auth_provider => "github",
                                       :auth_uid => auth_uid } }
          assert_response :redirect
          follow_redirect!
        end
      end
    end

    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first

    assert_equal register_email.to.first, new_email
    # Check that the confirm account url is correct
    confirm_regex = Regexp.new("confirm_string=([a-zA-Z0-9%_-]*)")
    email_text_parts(register_email).each do |part|
      assert_match confirm_regex, part.body.to_s
    end
    confirm_string = CGI.unescape(email_text_parts(register_email).first.body.match(confirm_regex)[1])

    # Check the page
    assert_response :success
    assert_template "confirmations/confirm"

    # Go to the confirmation page
    get "/user/#{display_name}/confirm", :params => { :referer => "/welcome", :confirm_string => confirm_string }
    assert_response :success
    assert_template "confirmations/confirm"

    post "/user/#{display_name}/confirm", :params => { :referer => "/welcome", :confirm_string => confirm_string }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "site/welcome"
  end

  def test_user_create_wikipedia_success
    new_email = "newtester-wikipedia@osm.org"
    email_hmac = UsersController.message_hmac(new_email)
    display_name = "new_tester-wikipedia"
    password = "testtest"
    auth_uid = "123454321"

    OmniAuth.config.add_mock(:wikipedia,
                             :uid => auth_uid,
                             :info => { :email => new_email, :name => display_name })

    assert_difference("User.count") do
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        perform_enqueued_jobs do
          post auth_path(:provider => "wikipedia", :origin => "/user/new")
          assert_redirected_to auth_success_path(:provider => "wikipedia", :origin => "/user/new")
          follow_redirect!
          assert_redirected_to :controller => :users, :action => "new", :nickname => display_name,
                               :email => new_email, :email_hmac => email_hmac,
                               :auth_provider => "wikipedia", :auth_uid => auth_uid
          follow_redirect!
          post "/user",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "wikipedia",
                                       :auth_uid => "123454321",
                                       :pass_crypt => password,
                                       :pass_crypt_confirmation => password },
                            :read_ct => 1,
                            :read_tou => 1,
                            :email_hmac => email_hmac }
          assert_redirected_to welcome_path
          follow_redirect!
        end
      end
    end

    # Check the page
    assert_response :success
    assert_template "site/welcome"
  end

  def test_user_create_wikipedia_duplicate_email
    dup_user = create(:user)
    display_name = "new_tester-wikipedia"
    auth_uid = "123454321"

    OmniAuth.config.add_mock(:wikipedia,
                             :uid => auth_uid,
                             :info => { "email" => dup_user.email, :name => display_name })

    post auth_path(:provider => "wikipedia", :origin => "/user/new")
    assert_redirected_to auth_success_path(:provider => "wikipedia", :origin => "/user/new")
    follow_redirect!
    assert_redirected_to :controller => :users, :action => "new", :nickname => display_name,
                         :email => dup_user.email, :email_hmac => UsersController.message_hmac(dup_user.email),
                         :auth_provider => "wikipedia", :auth_uid => auth_uid
    follow_redirect!

    assert_response :success
    assert_template "users/new"
    assert_select "form > div > input.is-invalid#user_email"
  end

  def test_user_create_wikipedia_failure
    OmniAuth.config.mock_auth[:wikipedia] = :connection_failed

    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post auth_path(:provider => "wikipedia", :origin => "/user/new")
          assert_response :redirect
          follow_redirect!
          assert_redirected_to auth_failure_path(:strategy => "wikipedia", :message => "connection_failed", :origin => "/user/new")
          follow_redirect!
          assert_redirected_to "/user/new"
        end
      end
    end
  end

  def test_user_create_wikipedia_redirect
    orig_email = "redirect_tester_wikipedia_orig@osm.org"
    email_hmac = UsersController.message_hmac(orig_email)
    new_email = "redirect_tester_wikipedia@osm.org"
    display_name = "redirect_tester_wikipedia"
    auth_uid = "123454321"

    OmniAuth.config.add_mock(:wikipedia,
                             :uid => auth_uid,
                             :info => { :email => orig_email, :name => display_name })

    # nothing special about this page, just need a protected page to redirect back to.
    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post auth_path(:provider => "wikipedia", :origin => "/user/new")
          assert_redirected_to auth_success_path(:provider => "wikipedia", :origin => "/user/new")
          follow_redirect!
          assert_redirected_to :controller => :users, :action => "new", :nickname => display_name,
                               :email => orig_email, :email_hmac => email_hmac,
                               :auth_provider => "wikipedia", :auth_uid => auth_uid
          follow_redirect!

          post "/user",
               :params => { :user => { :email => new_email,
                                       :email_hmac => email_hmac,
                                       :display_name => display_name,
                                       :auth_provider => "wikipedia",
                                       :auth_uid => auth_uid } }
          assert_response :redirect
          follow_redirect!
        end
      end
    end

    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first

    assert_equal register_email.to.first, new_email
    # Check that the confirm account url is correct
    confirm_regex = Regexp.new("confirm_string=([a-zA-Z0-9%_-]*)")
    email_text_parts(register_email).each do |part|
      assert_match confirm_regex, part.body.to_s
    end
    confirm_string = CGI.unescape(email_text_parts(register_email).first.body.match(confirm_regex)[1])

    # Check the page
    assert_response :success
    assert_template "confirmations/confirm"

    # Go to the confirmation page
    get "/user/#{display_name}/confirm", :params => { :referer => "/welcome", :confirm_string => confirm_string }
    assert_response :success
    assert_template "confirmations/confirm"

    post "/user/#{display_name}/confirm", :params => { :referer => "/welcome", :confirm_string => confirm_string }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "site/welcome"
  end
end
