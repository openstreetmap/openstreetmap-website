require File.dirname(__FILE__) + '/../test_helper'

class UserCreationTest < ActionController::IntegrationTest
  fixtures :users

  def test_create_user_form
    I18n.available_locales.each do |locale|
      get '/user/new', {}, {"accept_language" => locale.to_s}
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
          post '/user/save', 
            {:user => { :email => dup_email, :email_confirmation => dup_email, :display_name => display_name, :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest"}},
            {"accept_language" => localer.to_s}
        end
      end
      assert_response :success                                                                       
      assert_template 'user/new'
      assert_equal response.headers['Content-Language'][0..1], localer.to_s[0..1] unless localer == :root
      assert_select "div#errorExplanation"
      assert_select "table#loginForm > tr > td > div[class=fieldWithErrors] > input#user_email"
      assert_no_missing_translations
    end
  end
  
  def test_user_create_submit_duplicate_username
    I18n.available_locales.each do |locale|
      dup_display_name = users(:public_user).display_name
      email = "#{locale.to_s}_new_tester"
      assert_difference('User.count', 0) do
        assert_difference('ActionMailer::Base.deliveries.size', 0) do
          post '/user/save',
          {:user => {:email => email, :email_confirmation => email, :display_name => dup_display_name, :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest"}},
          {"accept_language" => locale.to_s}
        end
      end
      assert_response :success
      assert_template 'user/new'
      assert_select "div#errorExplanation"
      assert_select "table#loginForm > tr > td > div[class=fieldWithErrors] > input#user_display_name"
      assert_no_missing_translations
    end
  end
  
  def test_user_create_success
    I18n.available_locales.each do |locale|
      new_email = "#{locale.to_s}newtester@osm.org"
      display_name = "#{locale.to_s}_new_tester"
      assert_difference('User.count') do
        assert_difference('ActionMailer::Base.deliveries.size', 1) do
          post_via_redirect "/user/save", 
            {:user => { :email => new_email, :email_confirmation => new_email, :display_name => display_name, :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest"}},
            {"accept_language" => "#{locale.to_s}"}
        end
      end
      
      # Check the e-mail
      register_email = ActionMailer::Base.deliveries.first
    
      assert_equal register_email.to[0], new_email
      # Check that the confirm account url is correct
      assert_match /#{@url}/, register_email.body
      
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
end
