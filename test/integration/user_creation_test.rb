require "test_helper"

class UserCreationTest < ActionDispatch::IntegrationTest
  fixtures :users

  def setup
    I18n.locale = "en"

    OmniAuth.config.test_mode = true
  end

  def teardown
    I18n.locale = "en"

    OmniAuth.config.mock_auth[:openid] = nil
    OmniAuth.config.mock_auth[:google] = nil
    OmniAuth.config.mock_auth[:facebook] = nil
    OmniAuth.config.mock_auth[:windowslive] = nil
    OmniAuth.config.mock_auth[:github] = nil
    OmniAuth.config.test_mode = false
  end

  def test_create_user_form
    I18n.available_locales.each do |locale|
      get_via_redirect "/user/new", {}, { "HTTP_ACCEPT_LANGUAGE" => locale.to_s }
      assert_response :success
      assert_template "user/new"
    end
  end

  def test_user_create_submit_duplicate_email
    I18n.available_locales.each do |locale|
      dup_email = users(:public_user).email
      display_name = "#{locale}_new_tester"
      assert_difference("User.count", 0) do
        assert_difference("ActionMailer::Base.deliveries.size", 0) do
          post "/user/new",
               { :user => { :email => dup_email, :email_confirmation => dup_email, :display_name => display_name, :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest" } },
               { "HTTP_ACCEPT_LANGUAGE" => locale.to_s }
        end
      end
      assert_response :success
      assert_template "user/new"
      assert_equal locale.to_s, response.headers["Content-Language"] unless locale == :root
      assert_select "form > fieldset > div.form-row > input.field_with_errors#user_email"
      assert_no_missing_translations
    end
  end

  def test_user_create_submit_duplicate_username
    I18n.available_locales.each do |locale|
      dup_display_name = users(:public_user).display_name
      email = "#{locale}_new_tester"
      assert_difference("User.count", 0) do
        assert_difference("ActionMailer::Base.deliveries.size", 0) do
          post "/user/new",
               { :user => { :email => email, :email_confirmation => email, :display_name => dup_display_name, :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest" } },
               { "HTTP_ACCEPT_LANGUAGE" => locale.to_s }
        end
      end
      assert_response :success
      assert_template "user/new"
      assert_select "form > fieldset > div.form-row > input.field_with_errors#user_display_name"
      assert_no_missing_translations
    end
  end

  def test_user_create_success
    I18n.available_locales.each do |locale|
      new_email = "#{locale}newtester@osm.org"
      display_name = "#{locale}_new_tester"

      assert_difference("User.count", 0) do
        assert_difference("ActionMailer::Base.deliveries.size", 0) do
          post "/user/new",
               :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest" }
        end
      end

      assert_redirected_to "/user/terms"

      assert_difference("User.count") do
        assert_difference("ActionMailer::Base.deliveries.size", 1) do
          post_via_redirect "/user/save", {},
                            { "HTTP_ACCEPT_LANGUAGE" => locale.to_s }
        end
      end

      # Check the e-mail
      register_email = ActionMailer::Base.deliveries.first

      assert_equal register_email.to[0], new_email
      # Check that the confirm account url is correct
      assert_match /#{@url}/, register_email.body.to_s

      # Check the page
      assert_response :success
      assert_template "user/confirm"

      ActionMailer::Base.deliveries.clear
    end
  end

  # Check that the user can successfully recover their password
  def lost_password_recovery_success
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
        post "/user/new",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :pass_crypt => password, :pass_crypt_confirmation => password }, :referer => referer
        assert_redirected_to "/user/terms"
        post_via_redirect "/user/save",
                          :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :pass_crypt => password, :pass_crypt_confirmation => password }
      end
    end

    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first

    assert_equal register_email.to[0], new_email
    # Check that the confirm account url is correct
    confirm_regex = Regexp.new("/user/redirect_tester/confirm\\?confirm_string=([a-zA-Z0-9]*)")
    register_email.parts.each do |part|
      assert_match confirm_regex, part.body.to_s
    end
    confirm_string = register_email.parts[0].body.match(confirm_regex)[1]

    # Check the page
    assert_response :success
    assert_template "user/confirm"

    ActionMailer::Base.deliveries.clear

    # Go to the confirmation page
    get "/user/#{display_name}/confirm", :confirm_string => confirm_string
    assert_response :success
    assert_template "user/confirm"

    post "/user/#{display_name}/confirm", :confirm_string => confirm_string
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
        post "/user/new",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "openid", :auth_uid => "http://localhost:1123/new.tester", :pass_crypt => "", :pass_crypt_confirmation => "" }
        assert_response :redirect
        assert_redirected_to auth_path(:provider => "openid", :openid_url => "http://localhost:1123/new.tester", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_success_path(:provider => "openid", :openid_url => "http://localhost:1123/new.tester", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to "/user/terms"
        post "/user/save",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "openid", :auth_uid => "http://localhost:1123/new.tester", :pass_crypt => password, :pass_crypt_confirmation => password }
        assert_response :redirect
        follow_redirect!
      end
    end

    # Check the page
    assert_response :success
    assert_template "user/confirm"

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_openid_failure
    OmniAuth.config.mock_auth[:openid] = :connection_failed

    new_email = "newtester-openid2@osm.org"
    display_name = "new_tester-openid2"
    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        post "/user/new",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "openid", :auth_uid => "http://localhost:1123/new.tester", :pass_crypt => "", :pass_crypt_confirmation => "" }
        assert_response :redirect
        assert_redirected_to auth_path(:provider => "openid", :openid_url => "http://localhost:1123/new.tester", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_success_path(:provider => "openid", :openid_url => "http://localhost:1123/new.tester", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_failure_path(:strategy => "openid", :message => "connection_failed", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        follow_redirect!
        assert_response :success
        assert_template "user/new"
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
        post "/user/new",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "openid", :auth_uid => "http://localhost:1123/new.tester", :pass_crypt => "", :pass_crypt_confirmation => "" }, :referer => referer
        assert_response :redirect
        assert_redirected_to auth_path(:provider => "openid", :openid_url => "http://localhost:1123/new.tester", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_success_path(:provider => "openid", :openid_url => "http://localhost:1123/new.tester", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to "/user/terms"
        post_via_redirect "/user/save",
                          :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "openid", :auth_uid => "http://localhost:1123/new.tester", :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest" }
      end
    end

    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first

    assert_equal register_email.to[0], new_email
    # Check that the confirm account url is correct
    confirm_regex = Regexp.new("/user/redirect_tester_openid/confirm\\?confirm_string=([a-zA-Z0-9]*)")
    register_email.parts.each do |part|
      assert_match confirm_regex, part.body.to_s
    end
    confirm_string = register_email.parts[0].body.match(confirm_regex)[1]

    # Check the page
    assert_response :success
    assert_template "user/confirm"

    ActionMailer::Base.deliveries.clear

    # Go to the confirmation page
    get "/user/#{display_name}/confirm", :confirm_string => confirm_string
    assert_response :success
    assert_template "user/confirm"

    post "/user/#{display_name}/confirm", :confirm_string => confirm_string
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "site/welcome"
  end

  def test_user_create_google_success
    OmniAuth.config.add_mock(:google, :uid => "123454321", :extra => {
                               :id_info => { "openid_id" => "http://localhost:1123/new.tester" }
                             })

    new_email = "newtester-google@osm.org"
    display_name = "new_tester-google"
    password = "testtest"
    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        post "/user/new",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "google", :pass_crypt => "", :pass_crypt_confirmation => "" }
        assert_response :redirect
        assert_redirected_to auth_path(:provider => "google", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_success_path(:provider => "google")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to "/user/terms"
        post "/user/save",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "google", :auth_uid => "123454321", :pass_crypt => password, :pass_crypt_confirmation => password }
        assert_response :redirect
        follow_redirect!
      end
    end

    # Check the page
    assert_response :success
    assert_template "user/confirm"

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_google_failure
    OmniAuth.config.mock_auth[:google] = :connection_failed

    new_email = "newtester-google2@osm.org"
    display_name = "new_tester-google2"
    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        post "/user/new",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "google", :pass_crypt => "", :pass_crypt_confirmation => "" }
        assert_response :redirect
        assert_redirected_to auth_path(:provider => "google", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_success_path(:provider => "google")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_failure_path(:strategy => "google", :message => "connection_failed", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        follow_redirect!
        assert_response :success
        assert_template "user/new"
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
        post "/user/new",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "google", :pass_crypt => "", :pass_crypt_confirmation => "" }, :referer => referer
        assert_response :redirect
        assert_redirected_to auth_path(:provider => "google", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_success_path(:provider => "google")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to "/user/terms"
        post_via_redirect "/user/save",
                          :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "google", :auth_uid => "http://localhost:1123/new.tester", :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest" }
      end
    end

    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first

    assert_equal register_email.to[0], new_email
    # Check that the confirm account url is correct
    confirm_regex = Regexp.new("/user/redirect_tester_google/confirm\\?confirm_string=([a-zA-Z0-9]*)")
    register_email.parts.each do |part|
      assert_match confirm_regex, part.body.to_s
    end
    confirm_string = register_email.parts[0].body.match(confirm_regex)[1]

    # Check the page
    assert_response :success
    assert_template "user/confirm"

    ActionMailer::Base.deliveries.clear

    # Go to the confirmation page
    get "/user/#{display_name}/confirm", :confirm_string => confirm_string
    assert_response :success
    assert_template "user/confirm"

    post "/user/#{display_name}/confirm", :confirm_string => confirm_string
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "site/welcome"
  end

  def test_user_create_facebook_success
    OmniAuth.config.add_mock(:facebook, :uid => "123454321")

    new_email = "newtester-facebook@osm.org"
    display_name = "new_tester-facebook"
    password = "testtest"
    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        post "/user/new",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "facebook", :pass_crypt => "", :pass_crypt_confirmation => "" }
        assert_response :redirect
        assert_redirected_to auth_path(:provider => "facebook", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_success_path(:provider => "facebook")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to "/user/terms"
        post "/user/save",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "facebook", :auth_uid => "123454321", :pass_crypt => password, :pass_crypt_confirmation => password }
        assert_response :redirect
        follow_redirect!
      end
    end

    # Check the page
    assert_response :success
    assert_template "user/confirm"

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_facebook_failure
    OmniAuth.config.mock_auth[:facebook] = :connection_failed

    new_email = "newtester-facebook2@osm.org"
    display_name = "new_tester-facebook2"
    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        post "/user/new",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "facebook", :pass_crypt => "", :pass_crypt_confirmation => "" }
        assert_response :redirect
        assert_redirected_to auth_path(:provider => "facebook", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_success_path(:provider => "facebook")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_failure_path(:strategy => "facebook", :message => "connection_failed", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        follow_redirect!
        assert_response :success
        assert_template "user/new"
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
        post "/user/new",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "facebook", :pass_crypt => "", :pass_crypt_confirmation => "" }, :referer => referer
        assert_response :redirect
        assert_redirected_to auth_path(:provider => "facebook", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_success_path(:provider => "facebook")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to "/user/terms"
        post_via_redirect "/user/save",
                          :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "facebook", :auth_uid => "http://localhost:1123/new.tester", :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest" }
      end
    end

    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first

    assert_equal register_email.to[0], new_email
    # Check that the confirm account url is correct
    confirm_regex = Regexp.new("/user/redirect_tester_facebook/confirm\\?confirm_string=([a-zA-Z0-9]*)")
    register_email.parts.each do |part|
      assert_match confirm_regex, part.body.to_s
    end
    confirm_string = register_email.parts[0].body.match(confirm_regex)[1]

    # Check the page
    assert_response :success
    assert_template "user/confirm"

    ActionMailer::Base.deliveries.clear

    # Go to the confirmation page
    get "/user/#{display_name}/confirm", :confirm_string => confirm_string
    assert_response :success
    assert_template "user/confirm"

    post "/user/#{display_name}/confirm", :confirm_string => confirm_string
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "site/welcome"
  end

  def test_user_create_windowslive_success
    OmniAuth.config.add_mock(:windowslive, :uid => "123454321")

    new_email = "newtester-windowslive@osm.org"
    display_name = "new_tester-windowslive"
    password = "testtest"
    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        post "/user/new",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "windowslive", :pass_crypt => "", :pass_crypt_confirmation => "" }
        assert_response :redirect
        assert_redirected_to auth_path(:provider => "windowslive", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_success_path(:provider => "windowslive", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to "/user/terms"
        post "/user/save",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "windowslive", :auth_uid => "123454321", :pass_crypt => password, :pass_crypt_confirmation => password }
        assert_response :redirect
        follow_redirect!
      end
    end

    # Check the page
    assert_response :success
    assert_template "user/confirm"

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_windowslive_failure
    OmniAuth.config.mock_auth[:windowslive] = :connection_failed

    new_email = "newtester-windowslive2@osm.org"
    display_name = "new_tester-windowslive2"
    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        post "/user/new",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "windowslive", :pass_crypt => "", :pass_crypt_confirmation => "" }
        assert_response :redirect
        assert_redirected_to auth_path(:provider => "windowslive", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_success_path(:provider => "windowslive", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_failure_path(:strategy => "windowslive", :message => "connection_failed", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        follow_redirect!
        assert_response :success
        assert_template "user/new"
      end
    end

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_windowslive_redirect
    OmniAuth.config.add_mock(:windowslive, :uid => "123454321")

    new_email = "redirect_tester_windowslive@osm.org"
    display_name = "redirect_tester_windowslive"
    # nothing special about this page, just need a protected page to redirect back to.
    referer = "/traces/mine"
    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        post "/user/new",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "windowslive", :pass_crypt => "", :pass_crypt_confirmation => "" }, :referer => referer
        assert_response :redirect
        assert_redirected_to auth_path(:provider => "windowslive", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_success_path(:provider => "windowslive", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to "/user/terms"
        post_via_redirect "/user/save",
                          :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "windowslive", :auth_uid => "http://localhost:1123/new.tester", :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest" }
      end
    end

    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first

    assert_equal register_email.to[0], new_email
    # Check that the confirm account url is correct
    confirm_regex = Regexp.new("/user/redirect_tester_windowslive/confirm\\?confirm_string=([a-zA-Z0-9]*)")
    register_email.parts.each do |part|
      assert_match confirm_regex, part.body.to_s
    end
    confirm_string = register_email.parts[0].body.match(confirm_regex)[1]

    # Check the page
    assert_response :success
    assert_template "user/confirm"

    ActionMailer::Base.deliveries.clear

    # Go to the confirmation page
    get "/user/#{display_name}/confirm", :confirm_string => confirm_string
    assert_response :success
    assert_template "user/confirm"

    post "/user/#{display_name}/confirm", :confirm_string => confirm_string
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "site/welcome"
  end

  def test_user_create_github_success
    OmniAuth.config.add_mock(:github, :uid => "123454321")

    new_email = "newtester-github@osm.org"
    display_name = "new_tester-github"
    password = "testtest"
    assert_difference("User.count") do
      assert_difference("ActionMailer::Base.deliveries.size", 1) do
        post "/user/new",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "github", :pass_crypt => "", :pass_crypt_confirmation => "" }
        assert_response :redirect
        assert_redirected_to auth_path(:provider => "github", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_success_path(:provider => "github", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to "/user/terms"
        post "/user/save",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "github", :auth_uid => "123454321", :pass_crypt => password, :pass_crypt_confirmation => password }
        assert_response :redirect
        follow_redirect!
      end
    end

    # Check the page
    assert_response :success
    assert_template "user/confirm"

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_github_failure
    OmniAuth.config.mock_auth[:github] = :connection_failed

    new_email = "newtester-github2@osm.org"
    display_name = "new_tester-github2"
    assert_difference("User.count", 0) do
      assert_difference("ActionMailer::Base.deliveries.size", 0) do
        post "/user/new",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "github", :pass_crypt => "", :pass_crypt_confirmation => "" }
        assert_response :redirect
        assert_redirected_to auth_path(:provider => "github", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_success_path(:provider => "github", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_failure_path(:strategy => "github", :message => "connection_failed", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        follow_redirect!
        assert_response :success
        assert_template "user/new"
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
        post "/user/new",
             :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "github", :pass_crypt => "", :pass_crypt_confirmation => "" }, :referer => referer
        assert_response :redirect
        assert_redirected_to auth_path(:provider => "github", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to auth_success_path(:provider => "github", :origin => "/user/new")
        follow_redirect!
        assert_response :redirect
        assert_redirected_to "/user/terms"
        post_via_redirect "/user/save",
                          :user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :auth_provider => "github", :auth_uid => "http://localhost:1123/new.tester", :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest" }
      end
    end

    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first

    assert_equal register_email.to[0], new_email
    # Check that the confirm account url is correct
    confirm_regex = Regexp.new("/user/redirect_tester_github/confirm\\?confirm_string=([a-zA-Z0-9]*)")
    register_email.parts.each do |part|
      assert_match confirm_regex, part.body.to_s
    end
    confirm_string = register_email.parts[0].body.match(confirm_regex)[1]

    # Check the page
    assert_response :success
    assert_template "user/confirm"

    ActionMailer::Base.deliveries.clear

    # Go to the confirmation page
    get "/user/#{display_name}/confirm", :confirm_string => confirm_string
    assert_response :success
    assert_template "user/confirm"

    post "/user/#{display_name}/confirm", :confirm_string => confirm_string
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "site/welcome"
  end
end
