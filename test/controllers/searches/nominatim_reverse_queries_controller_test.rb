# frozen_string_literal: true

require_relative "queries_controller_test"

module Searches
  class NominatimReverseQueriesControllerTest < QueriesControllerTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/search/nominatim_reverse_query", :method => :post },
        { :controller => "searches/nominatim_reverse_queries", :action => "create" }
      )
    end

    def test_create
      with_http_stubs "nominatim" do
        post search_nominatim_reverse_query_path(:lat => 51.7632, :lon => -0.0076, :zoom => 15), :xhr => true
        results_check :name => "Broxbourne, Hertfordshire, East of England, England, United Kingdom",
                      :lat => 51.7465723, :lon => -0.0190782,
                      :type => "node", :id => 28825933, :zoom => 15

        post search_nominatim_reverse_query_path(:lat => 51.7632, :lon => -0.0076, :zoom => 17), :xhr => true
        results_check :name => "Dinant Link Road, Broxbourne, Hertfordshire, East of England, England, EN11 8HX, United Kingdom",
                      :lat => 51.7634883, :lon => -0.0088373,
                      :type => "way", :id => 3489841, :zoom => 17

        post search_nominatim_reverse_query_path(:lat => 13.7709, :lon => 100.50507, :zoom => 19), :xhr => true
        results_check :name => "MM Steak&Grill, ถนนศรีอยุธยา, บางขุนพรหม, กรุงเทพมหานคร, เขตดุสิต, กรุงเทพมหานคร, 10300, ประเทศไทย",
                      :lat => 13.7708691, :lon => 100.505073233221,
                      :type => "way", :id => 542901374, :zoom => 19
      end
    end
  end
end
