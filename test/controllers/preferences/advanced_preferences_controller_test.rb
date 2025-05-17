require "test_helper"

module Preferences
  class AdvancedPreferencesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/preferences/advanced", :method => :get },
        { :controller => "preferences/advanced_preferences", :action => "show" }
      )
      assert_routing(
        { :path => "/preferences/advanced", :method => :put },
        { :controller => "preferences/advanced_preferences", :action => "update" }
      )
    end
  end
end
