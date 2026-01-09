# frozen_string_literal: true

require_relative "queries_controller_test"

module Searches
  class NominatimQueriesControllerTest < QueriesControllerTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/search/nominatim_query", :method => :post },
        { :controller => "searches/nominatim_queries", :action => "create" }
      )
    end

    def test_create
      with_http_stubs "nominatim" do
        post search_nominatim_query_path(:query => "Hoddesdon", :zoom => 10,
                                         :minlon => -0.559, :minlat => 51.217,
                                         :maxlon => 0.836, :maxlat => 51.766), :xhr => true
        results_check "name" => "Hoddesdon, Hertfordshire, East of England, England, United Kingdom",
                      "min-lat" => 51.7216709, "max-lat" => 51.8016709,
                      "min-lon" => -0.0512898, "max-lon" => 0.0287102,
                      "type" => "node", "id" => 18007599

        post search_nominatim_query_path(:query => "Broxbourne", :zoom => 10,
                                         :minlon => -0.559, :minlat => 51.217,
                                         :maxlon => 0.836, :maxlat => 51.766), :xhr => true
        results_check({ "prefix" => "Suburb",
                        "name" => "Broxbourne, Hertfordshire, East of England, England, United Kingdom",
                        "min-lat" => 51.7265723, "max-lat" => 51.7665723,
                        "min-lon" => -0.0390782, "max-lon" => 0.0009218,
                        "type" => "node", "id" => 28825933 },
                      { "prefix" => "Village",
                        "name" => "Broxbourne, Hertfordshire, East of England, England, United Kingdom",
                        "min-lat" => 51.6808751, "max-lat" => 51.7806237,
                        "min-lon" => -0.114204, "max-lon" => 0.0145267,
                        "type" => "relation", "id" => 2677978 },
                      { "prefix" => "Railway Station",
                        "name" => "Broxbourne, Stafford Drive, Broxbourne, Hertfordshire, East of England, England, United Kingdom",
                        "min-lat" => 51.7418469, "max-lat" => 51.7518469,
                        "min-lon" => -0.0156773, "max-lon" => -0.0056773,
                        "type" => "node", "id" => 17044599 })
      end
    end
  end
end
