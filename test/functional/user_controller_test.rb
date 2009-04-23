require File.dirname(__FILE__) + '/../test_helper'

class UserControllerTest < ActionController::TestCase
  fixtures :users
  
  # The user creation page loads
  def test_user_create
    get :new
    assert_response :success
    assert_template 'new'
    
    assert_select "html:root", :count => 1 do
      assert_select "head", :count => 1 do
        assert_select "title", :text => /create account/, :count => 1
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
    
    # Private users can login and get the api details
    usr = users(:normal_user)
    basic_authorization(usr.email, "test")
    get :api_details
    assert_response :success
    # Now check the content of the XML returned
    print @response.body
    assert_select "osm:root[version=#{API_VERSION}][generator='#{GENERATOR}']", :count => 1 do
      assert_select "user[display_name='#{usr.display_name}'][account_created='#{usr.creation_time.xmlschema}']", :count => 1 do
      assert_select "home[lat='#{usr.home_lat}'][lon='#{usr.home_lon}'][zoom='#{usr.home_zoom}']", :count => 1
      end
    end
    
  end
  
  # Check that we can login through the web using the mixed case fixture,
  # lower case and upper case
  def test_user_login_web_case
    login_web_case_ok users(:normal_user).email,  "test"
    login_web_case_ok users(:normal_user).email.upcase, "test"
    login_web_case_ok users(:normal_user).email.downcase, "test"
  end

  def login_web_case_ok(userstring, password)
    post :login, :user => {:email => userstring, :password => password}
    assert_redirected_to :controller => 'site', :action => 'index'
  end

  # Check that we can login to the api, and get the user details 
  # using the mixed case fixture, lower case and upper case  
  def test_user_login_api_case
    login_api_case_ok users(:normal_user).email, "test"
    login_api_case_ok users(:normal_user).email.upcase, "test"
    login_api_case_ok users(:normal_user).email.downcase, "test"
  end
  
  def login_api_case_ok(userstring, password)
    basic_authorization(userstring, password)
    get :api_details
    assert :success
  end
end
