# frozen_string_literal: true

require "test_helper"

module Searches
  class QueriesControllerTest < ActionDispatch::IntegrationTest
    private

    def results_check(*results)
      assert_response :success
      assert_template :create
      assert_template :layout => nil
      if results.empty?
        assert_select "ul.results-list", 0
      else
        assert_select "ul.results-list", 1 do
          assert_select "li.search_results_entry", results.count

          results.each do |result|
            attrs = result.collect { |k, v| "[data-#{k}='#{v}']" }.join
            assert_select "li.search_results_entry a.set_position#{attrs}", result[:name]
          end
        end
      end
    end

    def json_results_check(*results)
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      results.zip(js) do |expected, actual|
        expected.each do |k, v|
          assert_equal v.to_s, actual[k.to_s]
        end
      end
    end

    def results_check_error(error)
      assert_response :success
      assert_template :error
      assert_template :layout => nil
      assert_select ".alert.alert-danger", error
    end
  end
end
