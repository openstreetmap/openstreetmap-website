# frozen_string_literal: true

require_relative "queries_controller_test"

module Searches
  class LatlonQueriesControllerTest < QueriesControllerTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/search/latlon_query", :method => :post },
        { :controller => "searches/latlon_queries", :action => "create" }
      )
    end

    def test_create
      post search_latlon_query_path(:lat => 1.23, :lon => 4.56, :zoom => 16), :xhr => true
      results_check :name => "1.23, 4.56", :lat => 1.23, :lon => 4.56, :zoom => 16

      post search_latlon_query_path(:lat => -91.23, :lon => 4.56, :zoom => 16), :xhr => true
      results_check_error "Latitude -91.23 out of range"

      post search_latlon_query_path(:lat => 91.23, :lon => 4.56, :zoom => 16), :xhr => true
      results_check_error "Latitude 91.23 out of range"

      post search_latlon_query_path(:lat => 1.23, :lon => -180.23, :zoom => 16), :xhr => true
      results_check_error "Longitude -180.23 out of range"

      post search_latlon_query_path(:lat => 1.23, :lon => 180.23, :zoom => 16), :xhr => true
      results_check_error "Longitude 180.23 out of range"
    end

    def test_create_digits
      post search_latlon_query_path(:lat => 1.23, :lon => 4.56, :zoom => 16, :latlon_digits => true), :xhr => true
      results_check({ :name => "1.23, 4.56", :lat => 1.23, :lon => 4.56, :zoom => 16 },
                    { :name => "4.56, 1.23", :lat => 4.56, :lon => 1.23, :zoom => 16 })

      post search_latlon_query_path(:lat => -91.23, :lon => 4.56, :zoom => 16, :latlon_digits => true), :xhr => true
      results_check :name => "4.56, -91.23", :lat => 4.56, :lon => -91.23, :zoom => 16

      post search_latlon_query_path(:lat => -1.23, :lon => 170.23, :zoom => 16, :latlon_digits => true), :xhr => true
      results_check :name => "-1.23, 170.23", :lat => -1.23, :lon => 170.23, :zoom => 16

      post search_latlon_query_path(:lat => 91.23, :lon => 94.56, :zoom => 16, :latlon_digits => true), :xhr => true
      results_check_error "Latitude or longitude are out of range"

      post search_latlon_query_path(:lat => -91.23, :lon => -94.56, :zoom => 16, :latlon_digits => true), :xhr => true
      results_check_error "Latitude or longitude are out of range"

      post search_latlon_query_path(:lat => 1.23, :lon => -180.23, :zoom => 16, :latlon_digits => true), :xhr => true
      results_check_error "Latitude or longitude are out of range"

      post search_latlon_query_path(:lat => 1.23, :lon => 180.23, :zoom => 16, :latlon_digits => true), :xhr => true
      results_check_error "Latitude or longitude are out of range"
    end
  end
end
