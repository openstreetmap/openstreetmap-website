require File.dirname(__FILE__) + '/../test_helper'

class UserPreferenceControllerTest < ActionController::TestCase
  fixtures :users, :user_preferences
  
  def test_read
    # first try without auth
    get :read
    assert_response :unauthorized, "should be authenticated"
    
    # now set the auth
    basic_authorization("test@openstreetmap.org", "test")
    
    get :read
    assert_response :success
    print @response.body
    assert_select "osm:root" do
      assert_select "preferences", :count => 1 do
        assert_select "preference", :count => 2
        assert_select "preference[k=\"#{user_preferences(:a).k}\"][v=\"#{user_preferences(:a).v}\"]", :count => 1
        assert_select "preference[k=\"#{user_preferences(:two).k}\"][v=\"#{user_preferences(:two).v}\"]", :count => 1
      end
    end
  end

end
