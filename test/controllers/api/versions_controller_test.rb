require "test_helper"

module Api
  class VersionsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/versions", :method => :get },
        { :controller => "api/versions", :action => "show" }
      )
      assert_routing(
        { :path => "/api/versions.json", :method => :get },
        { :controller => "api/versions", :action => "show", :format => "json" }
      )
      assert_recognizes(
        { :controller => "api/versions", :action => "show" },
        { :path => "/api/versions", :method => :get }
      )
      assert_recognizes(
        { :controller => "api/versions", :action => "show", :format => "json" },
        { :path => "/api/versions.json", :method => :get }
      )
    end

    def test_versions
      get api_versions_path
      assert_response :success
      assert_select "osm[generator='#{Settings.generator}']", :count => 1 do
        assert_select "api", :count => 1 do
          assert_select "version", Settings.api_version
        end
      end
    end

    def test_versions_json
      get api_versions_path, :params => { :format => "json" }
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal [Settings.api_version], js["api"]["versions"]
    end

    def test_no_version_in_root_element
      get api_versions_path
      assert_response :success
      assert_select "osm[version]", :count => 0
    end

    def test_versions_available_while_offline
      with_settings(:status => "api_offline") do
        get api_versions_path
        assert_response :success
        assert_select "osm[generator='#{Settings.generator}']", :count => 1 do
          assert_select "api", :count => 1 do
            assert_select "version", Settings.api_version
          end
        end
      end
    end
  end
end
