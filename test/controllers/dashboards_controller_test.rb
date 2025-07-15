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

  def test_show_unauthorized
    get dashboard_path

    assert_redirected_to login_path(:referer => dashboard_path)
  end
end
