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
    end

    def test_permissions_anonymous
      get permissions_path
      assert_response :success
      assert_select "osm > permissions", :count => 1 do
        assert_select "permission", :count => 0
      end
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
    end

    def test_permissions_oauth
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
  end
end
