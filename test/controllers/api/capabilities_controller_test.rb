require "test_helper"

module Api
  class CapabilitiesControllerTest < ActionController::TestCase
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/capabilities", :method => :get },
        { :controller => "api/capabilities", :action => "show" }
      )
      assert_recognizes(
        { :controller => "api/capabilities", :action => "show" },
        { :path => "/api/0.6/capabilities", :method => :get }
      )
    end

    def test_capabilities
      get :show
      assert_response :success
      assert_select "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", :count => 1 do
        assert_select "api", :count => 1 do
          assert_select "version[minimum='#{Settings.api_version}'][maximum='#{Settings.api_version}']", :count => 1
          assert_select "area[maximum='#{Settings.max_request_area}']", :count => 1
          assert_select "note_area[maximum='#{Settings.max_note_request_area}']", :count => 1
          assert_select "tracepoints[per_page='#{Settings.tracepoints_per_page}']", :count => 1
          assert_select "changesets[maximum_elements='#{Changeset::MAX_ELEMENTS}']", :count => 1
          assert_select "status[database='online']", :count => 1
          assert_select "status[api='online']", :count => 1
          assert_select "status[gpx='online']", :count => 1
        end
      end
    end
  end
end
