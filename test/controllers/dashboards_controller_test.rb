require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/dashboard", :method => :get },
      { :controller => "dashboards", :action => "show" }
    )
  end
end
