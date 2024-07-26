require "test_helper"

module Features
  class QueriesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/query", :method => :get },
        { :controller => "features/queries", :action => "show" }
      )
    end

    def test_show
      get features_query_path

      assert_response :success
      assert_template "features/queries/show"
    end
  end
end
