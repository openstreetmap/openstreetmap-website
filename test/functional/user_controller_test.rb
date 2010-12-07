require File.dirname(__FILE__) + '/../test_helper'

class UserControllerTest < ActionController::TestCase
  fixtures :users
  
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
    dup_email = users(:public_user).email
    display_name = "new_tester"
    assert_difference('User.count', 0) do
      assert_difference('ActionMailer::Base.deliveries.size', 0) do
        post :save, :user => { :email => dup_email, :email_confirmation => dup_email, :display_name => display_name, :pass_crypt => "testtest", :pass_crypt_confirmation => "testtest"}
      end
    end
    assert_response :success                                                                       
    assert_template 'new'
    assert_select "div#errorExplanation"
    assert_select "table#signupForm > tr > td > div[class=field_with_errors] > input#user_email"
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
