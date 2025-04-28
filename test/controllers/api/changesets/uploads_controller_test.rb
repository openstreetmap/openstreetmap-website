require "test_helper"

module Api
  module Changesets
    class UploadsControllerTest < ActionDispatch::IntegrationTest
      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/changeset/1/upload", :method => :post },
          { :controller => "api/changesets/uploads", :action => "create", :changeset_id => "1" }
        )
      end
    end
  end
end
