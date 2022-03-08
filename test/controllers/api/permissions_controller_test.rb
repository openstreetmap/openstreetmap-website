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

    def test_permissions_basic_auth
      auth_header = basic_authorization_header create(:user).email, "test"
      get permissions_path, :headers => auth_header
      assert_response :success
      assert_select "osm > permissions", :count => 1 do
        assert_select "permission", :count => ClientApplication.all_permissions.size
        ClientApplication.all_permissions.each do |p|
          assert_select "permission[name='#{p}']", :count => 1
        end
      end

      # Test json
      get permissions_path(:format => "json"), :headers => auth_header
      assert_response :success
      assert_equal "application/json", @response.media_type

      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal ClientApplication.all_permissions.size, js["permissions"].count
      ClientApplication.all_permissions.each do |p|
        assert_includes js["permissions"], p.to_s
      end
    end

    def test_permissions_oauth1
      token = create(:access_token,
                     :allow_read_prefs => true,
                     :allow_write_api => true,
                     :allow_read_gpx => false)
      signed_get permissions_path, :oauth => { :token => token }
      assert_response :success
      assert_select "osm > permissions", :count => 1 do
        assert_select "permission", :count => 2
        assert_select "permission[name='allow_read_prefs']", :count => 1
        assert_select "permission[name='allow_write_api']", :count => 1
        assert_select "permission[name='allow_read_gpx']", :count => 0
      end
    end

    def test_permissions_oauth2
      user = create(:user)
      token = create(:oauth_access_token,
                     :resource_owner_id => user.id,
                     :scopes => %w[read_prefs write_api])
      get permissions_path, :headers => bearer_authorization_header(token.token)
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
