require File.dirname(__FILE__) + '/../test_helper'

class UserPreferenceControllerTest < ActionController::TestCase
  fixtures :users, :user_preferences

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/user/preferences", :method => :get },
      { :controller => "user_preference", :action => "read" }
    )
    assert_routing(
      { :path => "/api/0.6/user/preferences", :method => :put },
      { :controller => "user_preference", :action => "update" }
    )
    assert_routing(
      { :path => "/api/0.6/user/preferences/key", :method => :get },
      { :controller => "user_preference", :action => "read_one", :preference_key => "key" }
    )
    assert_routing(
      { :path => "/api/0.6/user/preferences/key", :method => :put },
      { :controller => "user_preference", :action => "update_one", :preference_key => "key" }
    )
    assert_routing(
      { :path => "/api/0.6/user/preferences/key", :method => :delete },
      { :controller => "user_preference", :action => "delete_one", :preference_key => "key" }
    )
  end

  def test_read
    # first try without auth
    get :read
    assert_response :unauthorized, "should be authenticated"
    
    # now set the auth
    basic_authorization("test@openstreetmap.org", "test")
    
    get :read
    assert_response :success
    assert_select "osm" do
      assert_select "preferences", :count => 1 do
        assert_select "preference", :count => 2
        assert_select "preference[k=\"#{user_preferences(:a).k}\"][v=\"#{user_preferences(:a).v}\"]", :count => 1
        assert_select "preference[k=\"#{user_preferences(:two).k}\"][v=\"#{user_preferences(:two).v}\"]", :count => 1
      end
    end
  end
end
