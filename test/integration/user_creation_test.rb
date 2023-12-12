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
          post "/user/new",
               :params => { :user => { :email => dup_email,
                                       :display_name => display_name,
                                       :pass_crypt => "testtest",
                                       :pass_crypt_confirmation => "testtest",
                                       :consider_pd => "1" } }
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
          post "/user/new",
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
          post "/user/new",
               :params => { :user => { :email => email,
                                       :display_name => display_name,
                                       :pass_crypt => "testtest",
                                       :pass_crypt_confirmation => "blahblah" } }
        end
      end
    end
    assert_response :success
    assert_template "users/new"
    assert_select "form > div > input.is-invalid#user_pass_crypt_confirmation"
  end

  def test_user_create_success
    new_email = "newtester@osm.org"
    display_name = "new_tester"

    assert_difference("User.count", 1) do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :pass_crypt => "testtest",
                                       :pass_crypt_confirmation => "testtest",
                                       :consider_pd => "1" } }
          assert_response :redirect
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
    ActionMailer::Base.deliveries.clear

    post confirmation_url

    assert_redirected_to welcome_path

    user.reload
    assert_predicate user, :active?

    assert_equal user, User.authenticate(:username => new_email, :password => "testtest")
  end

  # Check that the user can successfully recover their password
  def test_lost_password_recovery_success
    # Open the lost password form
    # Submit the lost password form
    # Check the e-mail
    # Submit the reset password token
    # Check that the password has changed, and the user can login
  end

  def test_user_create_redirect
    new_email = "redirect_tester@osm.org"
    display_name = "redirect_tester"
    password = "testtest"
    # nothing special about this page, just need a protected page to redirect back to.
    referer = "/traces/mine"
    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :pass_crypt => password,
                                       :pass_crypt_confirmation => password,
                                       :consider_pd => "1" },
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

    ActionMailer::Base.deliveries.clear

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
    OmniAuth.config.add_mock(:openid, :uid => "http://localhost:1123/new.tester")

    new_email = "newtester-openid@osm.org"
    display_name = "new_tester-openid"
    password = "testtest"
    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "openid",
                                       :auth_uid => "http://localhost:1123/new.tester",
                                       :pass_crypt => password,
                                       :pass_crypt_confirmation => password,
                                       :consider_pd => "1" } }
          assert_redirected_to auth_path(:provider => "openid", :openid_url => "http://localhost:1123/new.tester", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "openid", :openid_url => "http://localhost:1123/new.tester", :origin => "/user/new")
          follow_redirect!
          assert_redirected_to :controller => :confirmations, :action => :confirm, :display_name => display_name
          follow_redirect!
        end
      end
    end

    # Check the page
    assert_response :success
    assert_template "confirmations/confirm"

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_openid_failure
    OmniAuth.config.mock_auth[:openid] = :connection_failed

    new_email = "newtester-openid2@osm.org"
    display_name = "new_tester-openid2"
    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "openid",
                                       :auth_uid => "http://localhost:1123/new.tester",
                                       :pass_crypt => "testtest",
                                       :pass_crypt_confirmation => "testtest",
                                       :consider_pd => "1" } }
          assert_redirected_to auth_path(:provider => "openid", :openid_url => "http://localhost:1123/new.tester", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "openid", :openid_url => "http://localhost:1123/new.tester", :origin => "/user/new")
          follow_redirect!
          assert_redirected_to auth_failure_path(:strategy => "openid", :message => "connection_failed", :origin => "/user/new")
          follow_redirect!
          assert_response :redirect
          follow_redirect!
          assert_response :success
          assert_template "users/new"
        end
      end
    end

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_openid_redirect
    OmniAuth.config.add_mock(:openid, :uid => "http://localhost:1123/new.tester")

    new_email = "redirect_tester_openid@osm.org"
    display_name = "redirect_tester_openid"
    # nothing special about this page, just need a protected page to redirect back to.
    referer = "/traces/mine"
    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "openid",
                                       :auth_uid => "http://localhost:1123/new.tester",
                                       :pass_crypt => "testtest",
                                       :pass_crypt_confirmation => "testtest",
                                       :consider_pd => "1" },
                            :referer => referer }
          assert_redirected_to auth_path(:provider => "openid", :openid_url => "http://localhost:1123/new.tester", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "openid", :openid_url => "http://localhost:1123/new.tester", :origin => "/user/new")
          follow_redirect!
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

    ActionMailer::Base.deliveries.clear

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
    display_name = "new_tester-google"
    password = "testtest"

    OmniAuth.config.add_mock(:google, :uid => "123454321", :info => { "email" => new_email })

    assert_difference("User.count") do
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "google",
                                       :pass_crypt => password,
                                       :pass_crypt_confirmation => password,
                                       :consider_pd => "1" } }
          assert_redirected_to auth_path(:provider => "google", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "google")
          follow_redirect!
          assert_redirected_to welcome_path
          follow_redirect!
        end
      end
    end

    # Check the page
    assert_response :success
    assert_template "site/welcome"

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_google_failure
    OmniAuth.config.mock_auth[:google] = :connection_failed

    new_email = "newtester-google2@osm.org"
    display_name = "new_tester-google2"
    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "google",
                                       :pass_crypt => "",
                                       :pass_crypt_confirmation => "",
                                       :consider_pd => "1" } }
          assert_redirected_to auth_path(:provider => "google", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "google")
          follow_redirect!
          assert_redirected_to auth_failure_path(:strategy => "google", :message => "connection_failed", :origin => "/user/new")
          follow_redirect!
          assert_response :redirect
          follow_redirect!
          assert_response :success
          assert_template "users/new"
        end
      end
    end

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_google_redirect
    OmniAuth.config.add_mock(:google, :uid => "123454321", :extra => {
                               :id_info => { "openid_id" => "http://localhost:1123/new.tester" }
                             })

    new_email = "redirect_tester_google@osm.org"
    display_name = "redirect_tester_google"
    # nothing special about this page, just need a protected page to redirect back to.
    referer = "/traces/mine"
    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "google",
                                       :pass_crypt => "testtest",
                                       :pass_crypt_confirmation => "testtest",
                                       :consider_pd => "1" },
                            :referer => referer }
          assert_redirected_to auth_path(:provider => "google", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "google")
          follow_redirect!
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

    ActionMailer::Base.deliveries.clear

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
    display_name = "new_tester-facebook"
    password = "testtest"

    OmniAuth.config.add_mock(:facebook, :uid => "123454321", :info => { "email" => new_email })

    assert_difference("User.count") do
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "facebook",
                                       :pass_crypt => password,
                                       :pass_crypt_confirmation => password,
                                       :consider_pd => "1" } }
          assert_redirected_to auth_path(:provider => "facebook", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "facebook")
          follow_redirect!
          assert_redirected_to welcome_path
          follow_redirect!
        end
      end
    end

    # Check the page
    assert_response :success
    assert_template "site/welcome"

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_facebook_failure
    OmniAuth.config.mock_auth[:facebook] = :connection_failed

    new_email = "newtester-facebook2@osm.org"
    display_name = "new_tester-facebook2"
    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "facebook",
                                       :pass_crypt => "",
                                       :pass_crypt_confirmation => "",
                                       :consider_pd => "1" } }
          assert_redirected_to auth_path(:provider => "facebook", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "facebook")
          follow_redirect!
          assert_redirected_to auth_failure_path(:strategy => "facebook", :message => "connection_failed", :origin => "/user/new")
          follow_redirect!
          assert_response :redirect
          follow_redirect!
          assert_response :success
          assert_template "users/new"
        end
      end
    end

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_facebook_redirect
    OmniAuth.config.add_mock(:facebook, :uid => "123454321")

    new_email = "redirect_tester_facebook@osm.org"
    display_name = "redirect_tester_facebook"
    # nothing special about this page, just need a protected page to redirect back to.
    referer = "/traces/mine"
    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "facebook",
                                       :pass_crypt => "testtest",
                                       :pass_crypt_confirmation => "testtest",
                                       :consider_pd => "1" },
                            :referer => referer }
          assert_redirected_to auth_path(:provider => "facebook", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "facebook")
          follow_redirect!
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

    ActionMailer::Base.deliveries.clear

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
    display_name = "new_tester-microsoft"
    password = "testtest"

    OmniAuth.config.add_mock(:microsoft, :uid => "123454321", :info => { "email" => new_email })

    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "microsoft",
                                       :pass_crypt => password,
                                       :pass_crypt_confirmation => password,
                                       :consider_pd => "1" } }
          assert_redirected_to auth_path(:provider => "microsoft", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "microsoft")
          follow_redirect!
          assert_redirected_to welcome_path
          follow_redirect!
        end
      end
    end

    # Check the page
    assert_response :success
    assert_template "site/welcome"

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_microsoft_failure
    OmniAuth.config.mock_auth[:microsoft] = :connection_failed

    new_email = "newtester-microsoft2@osm.org"
    display_name = "new_tester-microsoft2"
    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "microsoft",
                                       :pass_crypt => "",
                                       :pass_crypt_confirmation => "",
                                       :consider_pd => "1" } }
          assert_redirected_to auth_path(:provider => "microsoft", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "microsoft")
          follow_redirect!
          assert_redirected_to auth_failure_path(:strategy => "microsoft", :message => "connection_failed", :origin => "/user/new")
          follow_redirect!
          assert_response :redirect
          follow_redirect!
          assert_response :success
          assert_template "users/new"
        end
      end
    end

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_microsoft_redirect
    OmniAuth.config.add_mock(:microsoft, :uid => "123454321")

    new_email = "redirect_tester_microsoft@osm.org"
    display_name = "redirect_tester_microsoft"
    # nothing special about this page, just need a protected page to redirect back to.
    referer = "/traces/mine"
    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "microsoft",
                                       :pass_crypt => "testtest",
                                       :pass_crypt_confirmation => "testtest",
                                       :consider_pd => "1" },
                            :referer => referer }
          assert_redirected_to auth_path(:provider => "microsoft", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "microsoft")
          follow_redirect!
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

    ActionMailer::Base.deliveries.clear

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
    display_name = "new_tester-github"
    password = "testtest"

    OmniAuth.config.add_mock(:github, :uid => "123454321", :info => { "email" => new_email })

    assert_difference("User.count") do
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "github",
                                       :pass_crypt => password,
                                       :pass_crypt_confirmation => password,
                                       :consider_pd => "1" } }
          assert_redirected_to auth_path(:provider => "github", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "github")
          follow_redirect!
          assert_redirected_to welcome_path
          follow_redirect!
        end
      end
    end

    # Check the page
    assert_response :success
    assert_template "site/welcome"

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_github_failure
    OmniAuth.config.mock_auth[:github] = :connection_failed

    new_email = "newtester-github2@osm.org"
    display_name = "new_tester-github2"
    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "github",
                                       :pass_crypt => "",
                                       :pass_crypt_confirmation => "",
                                       :consider_pd => "1" } }
          assert_redirected_to auth_path(:provider => "github", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "github")
          follow_redirect!
          assert_redirected_to auth_failure_path(:strategy => "github", :message => "connection_failed", :origin => "/user/new")
          follow_redirect!
          assert_response :redirect
          follow_redirect!
          assert_response :success
          assert_template "users/new"
        end
      end
    end

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_github_redirect
    OmniAuth.config.add_mock(:github, :uid => "123454321")

    new_email = "redirect_tester_github@osm.org"
    display_name = "redirect_tester_github"
    # nothing special about this page, just need a protected page to redirect back to.
    referer = "/traces/mine"
    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "github",
                                       :pass_crypt => "testtest",
                                       :pass_crypt_confirmation => "testtest",
                                       :consider_pd => "1" },
                            :referer => referer }
          assert_redirected_to auth_path(:provider => "github", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "github")
          follow_redirect!
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

    ActionMailer::Base.deliveries.clear

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
    display_name = "new_tester-wikipedia"
    password = "testtest"

    OmniAuth.config.add_mock(:wikipedia, :uid => "123454321", :info => { "email" => new_email })

    assert_difference("User.count") do
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "wikipedia",
                                       :pass_crypt => password,
                                       :pass_crypt_confirmation => password,
                                       :consider_pd => "1" } }
          assert_redirected_to auth_path(:provider => "wikipedia", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "wikipedia", :origin => "/user/new")
          follow_redirect!
          assert_redirected_to welcome_path
          follow_redirect!
        end
      end
    end

    # Check the page
    assert_response :success
    assert_template "site/welcome"

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_wikipedia_failure
    OmniAuth.config.mock_auth[:wikipedia] = :connection_failed

    new_email = "newtester-wikipedia2@osm.org"
    display_name = "new_tester-wikipedia2"
    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "wikipedia",
                                       :pass_crypt => "",
                                       :pass_crypt_confirmation => "",
                                       :consider_pd => "1" } }
          assert_redirected_to auth_path(:provider => "wikipedia", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "wikipedia", :origin => "/user/new")
          follow_redirect!
          assert_redirected_to auth_failure_path(:strategy => "wikipedia", :message => "connection_failed", :origin => "/user/new")
          follow_redirect!
          assert_response :redirect
          follow_redirect!
          assert_response :success
          assert_template "users/new"
        end
      end
    end

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_wikipedia_redirect
    OmniAuth.config.add_mock(:wikipedia, :uid => "123454321")

    new_email = "redirect_tester_wikipedia@osm.org"
    display_name = "redirect_tester_wikipedia"
    # nothing special about this page, just need a protected page to redirect back to.
    referer = "/traces/mine"
    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        perform_enqueued_jobs do
          post "/user/new",
               :params => { :user => { :email => new_email,
                                       :display_name => display_name,
                                       :auth_provider => "wikipedia",
                                       :pass_crypt => "testtest",
                                       :pass_crypt_confirmation => "testtest",
                                       :consider_pd => "1" },
                            :referer => referer }
          assert_redirected_to auth_path(:provider => "wikipedia", :origin => "/user/new")
          post response.location
          assert_redirected_to auth_success_path(:provider => "wikipedia", :origin => "/user/new")
          follow_redirect!
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

    ActionMailer::Base.deliveries.clear

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
