require "test_helper"

module Api
  class VersionsControllerTest < ActionController::TestCase
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/versions", :method => :get },
        { :controller => "api/versions", :action => "show" }
      )
      assert_recognizes(
        { :controller => "api/versions", :action => "show" },
        { :path => "/api/versions", :method => :get }
      )
    end

    def test_versions
      get :show
      assert_response :success
      assert_select "osm[generator='#{Settings.generator}']", :count => 1 do
        assert_select "api", :count => 1 do
          assert_select "version", Settings.api_version
        end
      end
    end

    def test_no_version_in_root_element
      get :show
      assert_response :success
      assert_select "osm[version]", :count => 0
    end
  end
end
