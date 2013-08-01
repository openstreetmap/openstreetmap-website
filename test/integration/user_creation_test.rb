require File.dirname(__FILE__) + '/../test_helper'

class UserCreationTest < ActionController::IntegrationTest
  fixtures :users

  def setup
    openid_setup
  end

  def test_create_user_form
    I18n.available_locales.each do |locale|
      get_via_redirect '/user/new', {}, {"HTTP_ACCEPT_LANGUAGE" => locale.to_s}
      assert_response :success
      assert_template 'user/new'
    end
  end

  def test_user_create_submit_duplicate_email
    I18n.available_locales.each do |localer|
      dup_email = users(:public_user).email
      display_name = "#{localer.to_s}_new_tester"
      assert_difference('User.count', 0) do
        assert_difference('ActionMailer::Base.deliveries.size', 0) do
          post '/user/new',
            {:user => { :email => dup_email, :email_confirmation => dup_email, :display_name => display_name, :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest"}},
            {"HTTP_ACCEPT_LANGUAGE" => localer.to_s}
        end
      end
      assert_response :success
      assert_template 'user/new'
      assert_equal response.headers['Content-Language'][0..1], localer.to_s[0..1] unless localer == :root
      assert_select "div#errorExplanation"
      assert_select "form > fieldset > div.form-row > div.field_with_errors > input#user_email"
      assert_no_missing_translations
    end
  end

  def test_user_create_submit_duplicate_username
    I18n.available_locales.each do |locale|
      dup_display_name = users(:public_user).display_name
      email = "#{locale.to_s}_new_tester"
      assert_difference('User.count', 0) do
        assert_difference('ActionMailer::Base.deliveries.size', 0) do
          post '/user/new',
          {:user => {:email => email, :email_confirmation => email, :display_name => dup_display_name, :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest"}},
          {"HTTP_ACCEPT_LANGUAGE" => locale.to_s}
        end
      end
      assert_response :success
      assert_template 'user/new'
      assert_select "div#errorExplanation"
      assert_select "form > fieldset > div.form-row > div.field_with_errors > input#user_display_name"
      assert_no_missing_translations
    end
  end

  def test_user_create_success
    I18n.available_locales.each do |locale|
      new_email = "#{locale.to_s}newtester@osm.org"
      display_name = "#{locale.to_s}_new_tester"

      assert_difference('User.count', 0) do
        assert_difference('ActionMailer::Base.deliveries.size', 0) do
          post "/user/new",
            {:user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest"}}
          end
      end

      assert_redirected_to "/user/terms"

      assert_difference('User.count') do
        assert_difference('ActionMailer::Base.deliveries.size', 1) do
          post_via_redirect "/user/save", {},
            {"HTTP_ACCEPT_LANGUAGE" => "#{locale.to_s}"}
        end
      end

      # Check the e-mail
      register_email = ActionMailer::Base.deliveries.first

      assert_equal register_email.to[0], new_email
      # Check that the confirm account url is correct
      assert_match /#{@url}/, register_email.body.to_s

      # Check the page
      assert_response :success
      assert_template 'login'

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
    assert_difference('User.count') do
      assert_difference('ActionMailer::Base.deliveries.size', 1) do
        post "/user/new",
        {:user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :pass_crypt => password, :pass_crypt_confirmation => password}, :referer => referer }
        assert_redirected_to "/user/terms"
        post_via_redirect "/user/save",
        {:user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :pass_crypt => password, :pass_crypt_confirmation => password} }
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
    assert_template 'login'

    ActionMailer::Base.deliveries.clear

    # Go to the confirmation page
    get 'user/confirm', { :confirm_string => confirm_string }
    assert_response :success
    assert_template 'user/confirm'

    post 'user/confirm', { :confirm_string => confirm_string, :confirm_action => 'submit' }
    assert_response :redirect # to trace/mine in original referrer
    follow_redirect!
    assert_response :success
    assert_template 'site/welcome'
  end

  def test_user_create_openid_success
    new_email = "newtester-openid@osm.org"
    display_name = "new_tester-openid"
    password = "testtest"
    assert_difference('User.count') do
      assert_difference('ActionMailer::Base.deliveries.size', 1) do
        post "/user/new",
          {:user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :openid_url => "http://localhost:1123/john.doe?openid.success=newuser", :pass_crypt => "", :pass_crypt_confirmation => ""}}
        assert_response :redirect
        res = openid_request(@response.redirect_url)
        get "/user/new", res
        assert_redirected_to "/user/terms"
        post '/user/save',
          {:user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :openid_url => "http://localhost:1123/john.doe?openid.success=newuser", :pass_crypt => password, :pass_crypt_confirmation => password}}
        assert_response :redirect
        follow_redirect!
      end
    end

    # Check the page
    assert_response :success
    assert_template 'login'

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_openid_failure
    new_email = "newtester-openid2@osm.org"
    display_name = "new_tester-openid2"
    password = "testtest2"
    assert_difference('User.count',0) do
      assert_difference('ActionMailer::Base.deliveries.size',0) do
        post "/user/new",
          {:user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :openid_url => "http://localhost:1123/john.doe?openid.failure=newuser", :pass_crypt => "", :pass_crypt_confirmation => ""}}
        assert_response :redirect
        res = openid_request(@response.redirect_url)
        get '/user/new', res
        assert_response :success
        assert_template 'user/new'
      end
    end

    ActionMailer::Base.deliveries.clear
  end

  def test_user_create_openid_redirect
    new_email = "redirect_tester_openid@osm.org"
    display_name = "redirect_tester_openid"
    password = ""
    # nothing special about this page, just need a protected page to redirect back to.
    referer = "/traces/mine"
    assert_difference('User.count') do
      assert_difference('ActionMailer::Base.deliveries.size', 1) do
        post "/user/new",
          {:user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :openid_url => "http://localhost:1123/john.doe?openid.success=newuser", :pass_crypt => "", :pass_crypt_confirmation => ""}, :referer => referer }
        assert_response :redirect
        res = openid_request(@response.location)
        get "/user/new", res
        assert_redirected_to "/user/terms"
        post_via_redirect "/user/save",
          {:user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :openid_url => "http://localhost:1123/john.doe?openid.success=newuser", :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest"} }
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
    assert_template 'login'

    ActionMailer::Base.deliveries.clear

    # Go to the confirmation page
    get 'user/confirm', { :confirm_string => confirm_string }
    assert_response :success
    assert_template 'user/confirm'

    post 'user/confirm', { :confirm_string => confirm_string, :confirm_action => 'submit' }
    assert_response :redirect # to trace/mine in original referrer
    follow_redirect!
    assert_response :success
    assert_template 'site/welcome'
  end
end
