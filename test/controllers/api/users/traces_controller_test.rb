require "test_helper"

module Api
  module Users
    class TracesControllerTest < ActionDispatch::IntegrationTest
      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/user/gpx_files", :method => :get },
          { :controller => "api/users/traces", :action => "index" }
        )
      end

      def test_index
        user = create(:user)
        trace1 = create(:trace, :user => user) do |trace|
          create(:tracetag, :trace => trace, :tag => "London")
        end
        trace2 = create(:trace, :user => user) do |trace|
          create(:tracetag, :trace => trace, :tag => "Birmingham")
        end

        # check that we get a response when logged in
        auth_header = bearer_authorization_header user, :scopes => %w[read_gpx]
        get api_user_traces_path, :headers => auth_header
        assert_response :success
        assert_equal "application/xml", response.media_type

        # check the data that is returned
        assert_select "gpx_file[id='#{trace1.id}']", 1 do
          assert_select "tag", "London"
        end
        assert_select "gpx_file[id='#{trace2.id}']", 1 do
          assert_select "tag", "Birmingham"
        end
      end

      def test_index_anonymous
        get api_user_traces_path
        assert_response :unauthorized
      end

      def test_index_no_scope
        user = create(:user)
        bad_auth = bearer_authorization_header user, :scopes => %w[]

        get api_user_traces_path, :headers => bad_auth
        assert_response :forbidden
      end
    end
  end
end
