require "test_helper"

class BrowseControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/query", :method => :get },
      { :controller => "browse", :action => "query" }
    )
  end

  def test_query
    get query_path
    assert_response :success
    assert_template "browse/query"
  end
end
