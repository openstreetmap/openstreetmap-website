require "test_helper"

module Api
  class CapabilitiesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/capabilities", :method => :get },
        { :controller => "api/capabilities", :action => "show" }
      )
      assert_routing(
        { :path => "/api/capabilities.json", :method => :get },
        { :controller => "api/capabilities", :action => "show", :format => "json" }
      )
      assert_recognizes(
        { :controller => "api/capabilities", :action => "show" },
        { :path => "/api/0.6/capabilities", :method => :get }
      )
      assert_recognizes(
        { :controller => "api/capabilities", :action => "show", :format => "json" },
        { :path => "/api/0.6/capabilities.json", :method => :get }
      )
    end

    def test_capabilities
      get api_capabilities_path
      assert_response :success
      assert_select "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", :count => 1 do
        assert_select "api", :count => 1 do
          assert_select "version[minimum='#{Settings.api_version}'][maximum='#{Settings.api_version}']", :count => 1
          assert_select "area[maximum='#{Settings.max_request_area}']", :count => 1
          assert_select "note_area[maximum='#{Settings.max_note_request_area}']", :count => 1
          assert_select "tracepoints[per_page='#{Settings.tracepoints_per_page}']", :count => 1
          assert_select "changesets" \
                        "[maximum_elements='#{Changeset::MAX_ELEMENTS}']" \
                        "[default_query_limit='#{Settings.default_changeset_query_limit}']" \
                        "[maximum_query_limit='#{Settings.max_changeset_query_limit}']", :count => 1
          assert_select "relationmembers[maximum='#{Settings.max_number_of_relation_members}']", :count => 1
          assert_select "notes" \
                        "[default_query_limit='#{Settings.default_note_query_limit}']" \
                        "[maximum_query_limit='#{Settings.max_note_query_limit}']", :count => 1
          assert_select "status[database='online']", :count => 1
          assert_select "status[api='online']", :count => 1
          assert_select "status[gpx='online']", :count => 1
        end
      end
    end

    def test_capabilities_json
      get api_capabilities_path, :params => { :format => "json" }
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      assert_equal Settings.api_version, js["version"]
      assert_equal Settings.generator, js["generator"]
      assert_equal Settings.api_version, js["api"]["version"]["minimum"]
      assert_equal Settings.api_version, js["api"]["version"]["maximum"]
      assert_equal Settings.max_request_area, js["api"]["area"]["maximum"]
      assert_equal Settings.max_note_request_area, js["api"]["note_area"]["maximum"]
      assert_equal Settings.tracepoints_per_page, js["api"]["tracepoints"]["per_page"]
      assert_equal Changeset::MAX_ELEMENTS, js["api"]["changesets"]["maximum_elements"]
      assert_equal Settings.default_changeset_query_limit, js["api"]["changesets"]["default_query_limit"]
      assert_equal Settings.max_changeset_query_limit, js["api"]["changesets"]["maximum_query_limit"]
      assert_equal Settings.max_number_of_relation_members, js["api"]["relationmembers"]["maximum"]
      assert_equal Settings.default_note_query_limit, js["api"]["notes"]["default_query_limit"]
      assert_equal Settings.max_note_query_limit, js["api"]["notes"]["maximum_query_limit"]
      assert_equal "online", js["api"]["status"]["database"]
      assert_equal "online", js["api"]["status"]["api"]
      assert_equal "online", js["api"]["status"]["gpx"]
      assert_equal Settings.imagery_blacklist.length, js["policy"]["imagery"]["blacklist"].length
    end

    def test_capabilities_api_readonly
      with_settings(:status => "api_readonly") do
        get api_capabilities_path
        assert_response :success
        assert_select "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", :count => 1 do
          assert_select "api", :count => 1 do
            assert_select "status[database='online']", :count => 1
            assert_select "status[api='readonly']", :count => 1
            assert_select "status[gpx='online']", :count => 1
          end
        end
      end
    end

    def test_capabilities_api_offline
      with_settings(:status => "api_offline") do
        get api_capabilities_path
        assert_response :success
        assert_select "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", :count => 1 do
          assert_select "api", :count => 1 do
            assert_select "status[database='online']", :count => 1
            assert_select "status[api='offline']", :count => 1
            assert_select "status[gpx='online']", :count => 1
          end
        end
      end
    end

    def test_capabilities_database_readonly
      with_settings(:status => "database_readonly") do
        get api_capabilities_path
        assert_response :success
        assert_select "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", :count => 1 do
          assert_select "api", :count => 1 do
            assert_select "status[database='readonly']", :count => 1
            assert_select "status[api='readonly']", :count => 1
            assert_select "status[gpx='readonly']", :count => 1
          end
        end
      end
    end

    def test_capabilities_database_offline
      with_settings(:status => "database_offline") do
        get api_capabilities_path
        assert_response :success
        assert_select "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", :count => 1 do
          assert_select "api", :count => 1 do
            assert_select "status[database='offline']", :count => 1
            assert_select "status[api='offline']", :count => 1
            assert_select "status[gpx='offline']", :count => 1
          end
        end
      end
    end

    def test_capabilities_gpx_offline
      with_settings(:status => "gpx_offline") do
        get api_capabilities_path
        assert_response :success
        assert_select "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", :count => 1 do
          assert_select "api", :count => 1 do
            assert_select "status[database='online']", :count => 1
            assert_select "status[api='online']", :count => 1
            assert_select "status[gpx='offline']", :count => 1
          end
        end
      end
    end
  end
end
