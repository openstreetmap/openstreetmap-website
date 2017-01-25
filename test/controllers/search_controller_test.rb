require "test_helper"

class SearchControllerTest < ActionController::TestCase
  api_fixtures

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

  ##
  # test searching nodes
  def test_search_nodes
    get :search_nodes, :type => "test"
    assert_response :service_unavailable
    assert_equal "Searching of nodes is currently unavailable", response.headers["Error"]

    get :search_nodes, :type => "test", :value => "yes"
    assert_response :service_unavailable
    assert_equal "Searching of nodes is currently unavailable", response.headers["Error"]

    get :search_nodes, :name => "Test Node"
    assert_response :service_unavailable
    assert_equal "Searching of nodes is currently unavailable", response.headers["Error"]
  end

  ##
  # test searching ways
  def test_search_ways
    [:visible_way, :invisible_way, :used_way].each do |way|
      create(:way_tag, :way => current_ways(way), :k => "test", :v => "yes")
    end
    create(:way_tag, :way => current_ways(:used_way), :k => "name", :v => "Test Way")

    get :search_ways, :type => "test"
    assert_response :service_unavailable
    assert_equal "Searching for a key without value is currently unavailable", response.headers["Error"]

    get :search_ways, :type => "test", :value => "yes"
    assert_response :success
    assert_select "way", 3

    get :search_ways, :name => "Test Way"
    assert_response :success
    assert_select "way", 1
  end

  ##
  # test searching relations
  def test_search_relations
    [:visible_relation, :invisible_relation, :used_relation].each do |relation|
      create(:relation_tag, :relation => current_relations(relation), :k => "test", :v => "yes")
    end
    create(:relation_tag, :relation => current_relations(:used_relation), :k => "name", :v => "Test Relation")

    get :search_relations, :type => "test"
    assert_response :service_unavailable
    assert_equal "Searching for a key without value is currently unavailable", response.headers["Error"]

    get :search_relations, :type => "test", :value => "yes"
    assert_response :success
    assert_select "relation", 3

    get :search_relations, :name => "Test Relation"
    assert_response :success
    assert_select "relation", 1
  end

  ##
  # test searching nodes, ways and relations
  def test_search_all
    get :search_all, :type => "test"
    assert_response :service_unavailable
    assert_equal "Searching of nodes is currently unavailable", response.headers["Error"]

    get :search_all, :type => "test", :value => "yes"
    assert_response :service_unavailable
    assert_equal "Searching of nodes is currently unavailable", response.headers["Error"]

    get :search_all, :name => "Test"
    assert_response :service_unavailable
    assert_equal "Searching of nodes is currently unavailable", response.headers["Error"]
  end
end
