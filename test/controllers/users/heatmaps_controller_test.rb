require "test_helper"

module Users
  class HeatmapsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/user/username/heatmap", :method => :get },
        { :controller => "users/heatmaps", :action => "show", :user_display_name => "username" }
      )
    end
  end
end
