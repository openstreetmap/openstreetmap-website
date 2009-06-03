require File.dirname(__FILE__) + '/../test_helper'

class UserControllerTest < ActionController::TestCase
  fixtures :users
  
  # The user creation page loads
  def test_user_create
    get :new
    assert_response :success
    
    assert_select "html:root", :count => 1 do
      assert_select "head", :count => 1 do
        assert_select "title", :text => /Create account/, :count => 1
      end
      assert_select "body", :count => 1 do
        assert_select "div#content", :count => 1 do
          assert_select "form[action='/user/save'][method=post]", :count => 1 do
            assert_select "input[id=user_email]", :count => 1
            assert_select "input[id=user_email_confirmation]", :count => 1
            assert_select "input[id=user_display_name]", :count => 1
            assert_select "input[id=user_pass_crypt][type=password]", :count => 1
            assert_select "input[id=user_pass_crypt_confirmation][type=password]", :count => 1
            assert_select "input[type=submit][value=Signup]", :count => 1
          end
        end
      end
    end
  end
  
  # Check that the user account page will display and contains some relevant
  # information for the user
  def test_view_user_account
    get :view
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
