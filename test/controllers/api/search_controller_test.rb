require "test_helper"

module Api
  class SearchControllerTest < ActionController::TestCase
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/search", :method => :get },
        { :controller => "api/search", :action => "search_all" }
      )
      assert_routing(
        { :path => "/api/0.6/nodes/search", :method => :get },
        { :controller => "api/search", :action => "search_nodes" }
      )
      assert_routing(
        { :path => "/api/0.6/ways/search", :method => :get },
        { :controller => "api/search", :action => "search_ways" }
      )
      assert_routing(
        { :path => "/api/0.6/relations/search", :method => :get },
        { :controller => "api/search", :action => "search_relations" }
      )
    end

    ##
    # test searching nodes
    def test_search_nodes
      get :search_nodes, :params => { :type => "test" }
      assert_response :service_unavailable
      assert_equal "Searching of nodes is currently unavailable", response.headers["Error"]

      get :search_nodes, :params => { :type => "test", :value => "yes" }
      assert_response :service_unavailable
      assert_equal "Searching of nodes is currently unavailable", response.headers["Error"]

      get :search_nodes, :params => { :name => "Test Node" }
      assert_response :service_unavailable
      assert_equal "Searching of nodes is currently unavailable", response.headers["Error"]
    end

    ##
    # test searching ways
    def test_search_ways
      first_way = create(:way_with_nodes, :nodes_count => 2)
      deleted_way = create(:way_with_nodes, :deleted, :nodes_count => 2)
      third_way = create(:way_with_nodes, :nodes_count => 2)

      [first_way, deleted_way, third_way].each do |way|
        create(:way_tag, :way => way, :k => "test", :v => "yes")
      end
      create(:way_tag, :way => third_way, :k => "name", :v => "Test Way")

      get :search_ways, :params => { :type => "test" }
      assert_response :service_unavailable
      assert_equal "Searching for a key without value is currently unavailable", response.headers["Error"]

      get :search_ways, :params => { :type => "test", :value => "yes" }
      assert_response :success
      assert_select "way", 3

      get :search_ways, :params => { :name => "Test Way" }
      assert_response :success
      assert_select "way", 1
    end

    ##
    # test searching relations
    def test_search_relations
      first_relation = create(:relation)
      deleted_relation = create(:relation)
      third_relation = create(:relation)

      [first_relation, deleted_relation, third_relation].each do |relation|
        create(:relation_tag, :relation => relation, :k => "test", :v => "yes")
      end
      create(:relation_tag, :relation => third_relation, :k => "name", :v => "Test Relation")

      get :search_relations, :params => { :type => "test" }
      assert_response :service_unavailable
      assert_equal "Searching for a key without value is currently unavailable", response.headers["Error"]

      get :search_relations, :params => { :type => "test", :value => "yes" }
      assert_response :success
      assert_select "relation", 3

      get :search_relations, :params => { :name => "Test Relation" }
      assert_response :success
      assert_select "relation", 1
    end

    ##
    # test searching nodes, ways and relations
    def test_search_all
      get :search_all, :params => { :type => "test" }
      assert_response :service_unavailable
      assert_equal "Searching of nodes is currently unavailable", response.headers["Error"]

      get :search_all, :params => { :type => "test", :value => "yes" }
      assert_response :service_unavailable
      assert_equal "Searching of nodes is currently unavailable", response.headers["Error"]

      get :search_all, :params => { :name => "Test" }
      assert_response :service_unavailable
      assert_equal "Searching of nodes is currently unavailable", response.headers["Error"]
    end
  end
end
