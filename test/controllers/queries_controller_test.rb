require "test_helper"

class QueriesControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/query", :method => :get },
      { :controller => "queries", :action => "show" }
    )
  end

  def test_show
    get query_path
    assert_response :success
    assert_template "queries/show"
  end
end
