# frozen_string_literal: true

require "test_helper"

class BrowseControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/query", :method => :get },
      { :controller => "feature_queries", :action => "show" }
    )
  end

  def test_show
    get feature_query_path
    assert_response :success
    assert_template "feature_queries/show"
  end
end
