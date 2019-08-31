require "test_helper"

module Api
  class PermissionsControllerTest < ActionController::TestCase
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/permissions", :method => :get },
        { :controller => "api/permissions", :action => "show" }
      )
    end

    def test_permissions_anonymous
      get :show
      assert_response :success
      assert_select "osm > permissions", :count => 1 do
        assert_select "permission", :count => 0
      end
    end

    def test_permissions_basic_auth
      basic_authorization create(:user).email, "test"
      get :show
      assert_response :success
      assert_select "osm > permissions", :count => 1 do
        assert_select "permission", :count => ClientApplication.all_permissions.size
        ClientApplication.all_permissions.each do |p|
          assert_select "permission[name='#{p}']", :count => 1
        end
      end
    end

    def test_permissions_oauth
      @request.env["oauth.token"] = AccessToken.new do |token|
        # Just to test a few
        token.allow_read_prefs = true
        token.allow_write_api = true
        token.allow_read_gpx = false
      end
      get :show
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
