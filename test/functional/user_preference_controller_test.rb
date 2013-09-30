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

  ##
  # test read action
  def test_read
    # first try without auth
    get :read
    assert_response :unauthorized, "should be authenticated"

    # authenticate as a user with no preferences
    basic_authorization("test@example.com", "test")

    # try the read again
    get :read
    assert_select "osm" do
      assert_select "preferences", :count => 1 do
        assert_select "preference", :count => 0
      end
    end
    
    # authenticate as a user with preferences
    basic_authorization("test@openstreetmap.org", "test")

    # try the read again
    get :read
    assert_response :success
    assert_equal "text/xml", @response.content_type
    assert_select "osm" do
      assert_select "preferences", :count => 1 do
        assert_select "preference", :count => 2
        assert_select "preference[k=\"#{user_preferences(:a).k}\"][v=\"#{user_preferences(:a).v}\"]", :count => 1
        assert_select "preference[k=\"#{user_preferences(:two).k}\"][v=\"#{user_preferences(:two).v}\"]", :count => 1
      end
    end
  end

  ##
  # test read_one action
  def test_read_one
    # try a read without auth
    get :read_one, :preference_key => "key"
    assert_response :unauthorized, "should be authenticated"

    # authenticate as a user with preferences
    basic_authorization("test@openstreetmap.org", "test")

    # try the read again
    get :read_one, :preference_key => "key"
    assert_response :success
    assert_equal "text/plain", @response.content_type
    assert_equal "value", @response.body

    # try the read again for a non-existent key
    get :read_one, :preference_key => "unknown_key"
    assert_response :not_found
  end

  ##
  # test update action
  def test_update
    # try a put without auth
    assert_no_difference "UserPreference.count" do
      content "<osm><preferences><preference k='key' v='new_value'/><preference k='new_key' v='value'/></preferences></osm>"
      put :update
    end
    assert_response :unauthorized, "should be authenticated"
    assert_equal "value", UserPreference.find(1, "key").v
    assert_equal "some_value", UserPreference.find(1, "some_key").v
    assert_raises ActiveRecord::RecordNotFound do
      UserPreference.find(1, "new_key")
    end

    # authenticate as a user with preferences
    basic_authorization("test@openstreetmap.org", "test")

    # try the put again
    assert_no_difference "UserPreference.count" do
      content "<osm><preferences><preference k='key' v='new_value'/><preference k='new_key' v='value'/></preferences></osm>"
      put :update
    end
    assert_response :success
    assert_equal "text/plain", @response.content_type
    assert_equal "", @response.body
    assert_equal "new_value", UserPreference.find(1, "key").v
    assert_equal "value", UserPreference.find(1, "new_key").v
    assert_raises ActiveRecord::RecordNotFound do
      UserPreference.find(1, "some_key")
    end

    # try a put with duplicate keys
    assert_no_difference "UserPreference.count" do
      content "<osm><preferences><preference k='key' v='value'/><preference k='key' v='newer_value'/></preferences></osm>"
      put :update
    end
    assert_response :bad_request
    assert_equal "text/plain", @response.content_type
    assert_equal "Duplicate preferences with key key", @response.body
    assert_equal "new_value", UserPreference.find(1, "key").v

    # try a put with invalid content
    assert_no_difference "UserPreference.count" do
      content "nonsense"
      put :update
    end
    assert_response :bad_request
  end

  ##
  # test update_one action
  def test_update_one
    # try a put without auth
    assert_no_difference "UserPreference.count" do
      content "new_value"
      put :update_one, :preference_key => "new_key"
    end
    assert_response :unauthorized, "should be authenticated"
    assert_raises ActiveRecord::RecordNotFound do
      UserPreference.find(1, "new_key")
    end

    # authenticate as a user with preferences
    basic_authorization("test@openstreetmap.org", "test")

    # try adding a new preference
    assert_difference "UserPreference.count", 1 do
      content "new_value"
      put :update_one, :preference_key => "new_key"
    end
    assert_response :success
    assert_equal "text/plain", @response.content_type
    assert_equal "", @response.body
    assert_equal "new_value", UserPreference.find(1, "new_key").v

    # try changing the value of a preference
    assert_no_difference "UserPreference.count" do
      content "newer_value"
      put :update_one, :preference_key => "new_key"
    end
    assert_response :success
    assert_equal "text/plain", @response.content_type
    assert_equal "", @response.body
    assert_equal "newer_value", UserPreference.find(1, "new_key").v
  end

  ##
  # test delete_one action
  def test_delete_one
    # try a delete without auth
    assert_no_difference "UserPreference.count" do
      delete :delete_one, :preference_key => "key"
    end
    assert_response :unauthorized, "should be authenticated"
    assert_equal "value", UserPreference.find(1, "key").v

    # authenticate as a user with preferences
    basic_authorization("test@openstreetmap.org", "test")

    # try the delete again
    assert_difference "UserPreference.count", -1 do
      get :delete_one, :preference_key => "key"
    end
    assert_response :success
    assert_equal "text/plain", @response.content_type
    assert_equal "", @response.body
    assert_raises ActiveRecord::RecordNotFound do
      UserPreference.find(1, "key")
    end

    # try the delete again for the same key
    assert_no_difference "UserPreference.count" do
      get :delete_one, :preference_key => "key"
    end
    assert_response :not_found
    assert_raises ActiveRecord::RecordNotFound do
      UserPreference.find(1, "key")
    end
  end
end
