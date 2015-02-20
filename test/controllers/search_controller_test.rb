require "test_helper"

class SearchControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/search", :method => :get },
      { :controller => "search", :action => "search_all" }
    )
    assert_routing(
      { :path => "/api/0.6/nodes/search", :method => :get },
      { :controller => "search", :action => "search_nodes" }
    )
    assert_routing(
      { :path => "/api/0.6/ways/search", :method => :get },
      { :controller => "search", :action => "search_ways" }
    )
    assert_routing(
      { :path => "/api/0.6/relations/search", :method => :get },
      { :controller => "search", :action => "search_relations" }
    )
  end
end
