require "test_helper"

module Api
  class UserPreferencesControllerTest < ActionController::TestCase
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/user/preferences", :method => :get },
        { :controller => "api/user_preferences", :action => "index" }
      )
      assert_routing(
        { :path => "/api/0.6/user/preferences", :method => :put },
        { :controller => "api/user_preferences", :action => "update_all" }
      )
      assert_routing(
        { :path => "/api/0.6/user/preferences/key", :method => :get },
        { :controller => "api/user_preferences", :action => "show", :preference_key => "key" }
      )
      assert_routing(
        { :path => "/api/0.6/user/preferences/key", :method => :put },
        { :controller => "api/user_preferences", :action => "update", :preference_key => "key" }
      )
      assert_routing(
        { :path => "/api/0.6/user/preferences/key", :method => :delete },
        { :controller => "api/user_preferences", :action => "destroy", :preference_key => "key" }
      )
    end

    ##
    # test showing all preferences
    def test_index
      # first try without auth
      get :index
      assert_response :unauthorized, "should be authenticated"

      # authenticate as a user with no preferences
      basic_authorization create(:user).email, "test"

      # try the read again
      get :index
      assert_select "osm" do
        assert_select "preferences", :count => 1 do
          assert_select "preference", :count => 0
        end
      end

      # authenticate as a user with preferences
      user = create(:user)
      user_preference = create(:user_preference, :user => user)
      user_preference2 = create(:user_preference, :user => user)
      basic_authorization user.email, "test"

      # try the read again
      get :index
      assert_response :success
      assert_equal "application/xml", @response.content_type
      assert_select "osm" do
        assert_select "preferences", :count => 1 do
          assert_select "preference", :count => 2
          assert_select "preference[k=\"#{user_preference.k}\"][v=\"#{user_preference.v}\"]", :count => 1
          assert_select "preference[k=\"#{user_preference2.k}\"][v=\"#{user_preference2.v}\"]", :count => 1
        end
      end
    end

    ##
    # test showing one preference
    def test_show
      user = create(:user)
      create(:user_preference, :user => user, :k => "key", :v => "value")

      # try a read without auth
      get :show, :params => { :preference_key => "key" }
      assert_response :unauthorized, "should be authenticated"

      # authenticate as a user with preferences
      basic_authorization user.email, "test"

      # try the read again
      get :show, :params => { :preference_key => "key" }
      assert_response :success
      assert_equal "text/plain", @response.content_type
      assert_equal "value", @response.body

      # try the read again for a non-existent key
      get :show, :params => { :preference_key => "unknown_key" }
      assert_response :not_found
    end

    ##
    # test bulk update action
    def test_update_all
      user = create(:user)
      create(:user_preference, :user => user, :k => "key", :v => "value")
      create(:user_preference, :user => user, :k => "some_key", :v => "some_value")

      # try a put without auth
      assert_no_difference "UserPreference.count" do
        put :update_all, :body => "<osm><preferences><preference k='key' v='new_value'/><preference k='new_key' v='value'/></preferences></osm>"
      end
      assert_response :unauthorized, "should be authenticated"
      assert_equal "value", UserPreference.find([user.id, "key"]).v
      assert_equal "some_value", UserPreference.find([user.id, "some_key"]).v
      assert_raises ActiveRecord::RecordNotFound do
        UserPreference.find([user.id, "new_key"])
      end

      # authenticate as a user with preferences
      basic_authorization user.email, "test"

      # try the put again
      assert_no_difference "UserPreference.count" do
        put :update_all, :body => "<osm><preferences><preference k='key' v='new_value'/><preference k='new_key' v='value'/></preferences></osm>"
      end
      assert_response :success
      assert_equal "text/plain", @response.content_type
      assert_equal "", @response.body
      assert_equal "new_value", UserPreference.find([user.id, "key"]).v
      assert_equal "value", UserPreference.find([user.id, "new_key"]).v
      assert_raises ActiveRecord::RecordNotFound do
        UserPreference.find([user.id, "some_key"])
      end

      # try a put with duplicate keys
      assert_no_difference "UserPreference.count" do
        put :update_all, :body => "<osm><preferences><preference k='key' v='value'/><preference k='key' v='newer_value'/></preferences></osm>"
      end
      assert_response :bad_request
      assert_equal "text/plain", @response.content_type
      assert_equal "Duplicate preferences with key key", @response.body
      assert_equal "new_value", UserPreference.find([user.id, "key"]).v

      # try a put with invalid content
      assert_no_difference "UserPreference.count" do
        put :update_all, :body => "nonsense"
      end
      assert_response :bad_request
    end

    ##
    # test update action
    def test_update
      user = create(:user)
      create(:user_preference, :user => user)

      # try a put without auth
      assert_no_difference "UserPreference.count" do
        put :update, :params => { :preference_key => "new_key" }, :body => "new_value"
      end
      assert_response :unauthorized, "should be authenticated"
      assert_raises ActiveRecord::RecordNotFound do
        UserPreference.find([user.id, "new_key"])
      end

      # authenticate as a user with preferences
      basic_authorization user.email, "test"

      # try adding a new preference
      assert_difference "UserPreference.count", 1 do
        put :update, :params => { :preference_key => "new_key" }, :body => "new_value"
      end
      assert_response :success
      assert_equal "text/plain", @response.content_type
      assert_equal "", @response.body
      assert_equal "new_value", UserPreference.find([user.id, "new_key"]).v

      # try changing the value of a preference
      assert_no_difference "UserPreference.count" do
        put :update, :params => { :preference_key => "new_key" }, :body => "newer_value"
      end
      assert_response :success
      assert_equal "text/plain", @response.content_type
      assert_equal "", @response.body
      assert_equal "newer_value", UserPreference.find([user.id, "new_key"]).v
    end

    ##
    # test destroy action
    def test_destroy
      user = create(:user)
      create(:user_preference, :user => user, :k => "key", :v => "value")

      # try a delete without auth
      assert_no_difference "UserPreference.count" do
        delete :destroy, :params => { :preference_key => "key" }
      end
      assert_response :unauthorized, "should be authenticated"
      assert_equal "value", UserPreference.find([user.id, "key"]).v

      # authenticate as a user with preferences
      basic_authorization user.email, "test"

      # try the delete again
      assert_difference "UserPreference.count", -1 do
        get :destroy, :params => { :preference_key => "key" }
      end
      assert_response :success
      assert_equal "text/plain", @response.content_type
      assert_equal "", @response.body
      assert_raises ActiveRecord::RecordNotFound do
        UserPreference.find([user.id, "key"])
      end

      # try the delete again for the same key
      assert_no_difference "UserPreference.count" do
        get :destroy, :params => { :preference_key => "key" }
      end
      assert_response :not_found
      assert_raises ActiveRecord::RecordNotFound do
        UserPreference.find([user.id, "key"])
      end
    end

    # Ensure that a valid access token with correct capabilities can be used to
    # read preferences
    def test_show_using_token
      user = create(:user)
      token = create(:access_token, :user => user, :allow_read_prefs => true)
      create(:user_preference, :user => user, :k => "key", :v => "value")

      # Hack together an oauth request - an alternative would be to sign the request properly
      @request.env["oauth.version"] = 1
      @request.env["oauth.strategies"] = [:token]
      @request.env["oauth.token"] = token

      get :show, :params => { :preference_key => "key" }
      assert_response :success
    end

    # Ensure that a valid access token with incorrect capabilities can't be used
    # to read preferences even, though the owner of that token could read them
    # by other methods.
    def test_show_using_token_fail
      user = create(:user)
      token = create(:access_token, :user => user, :allow_read_prefs => false)
      create(:user_preference, :user => user, :k => "key", :v => "value")
      @request.env["oauth.version"] = 1
      @request.env["oauth.strategies"] = [:token]
      @request.env["oauth.token"] = token

      get :show, :params => { :preference_key => "key" }
      assert_response :forbidden
    end
  end
end
