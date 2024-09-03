require "test_helper"

module Api
  class PermissionsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/permissions", :method => :get },
        { :controller => "api/permissions", :action => "show" }
      )
      assert_routing(
        { :path => "/api/0.6/permissions.json", :method => :get },
        { :controller => "api/permissions", :action => "show", :format => "json" }
      )
    end

    def test_permissions_anonymous
      get permissions_path
      assert_response :success
      assert_select "osm > permissions", :count => 1 do
        assert_select "permission", :count => 0
      end

      # Test json
      get permissions_path(:format => "json")
      assert_response :success
      assert_equal "application/json", @response.media_type

      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 0, js["permissions"].count
    end

    def test_permissions_oauth2
      user = create(:user)
      auth_header = bearer_authorization_header(user, :scopes => %w[read_prefs write_api])
      get permissions_path, :headers => auth_header
      assert_response :success
      assert_select "osm > permissions", :count => 1 do
        assert_select "permission", :count => 2
        assert_select "permission[name='allow_read_prefs']", :count => 1
        assert_select "permission[name='allow_write_api']", :count => 1
        assert_select "permission[name='allow_read_gpx']", :count => 0
      end
    end
  end
end
