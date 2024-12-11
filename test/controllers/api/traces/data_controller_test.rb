require "test_helper"

module Api
  module Traces
    class DataControllerTest < ActionDispatch::IntegrationTest
      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/gpx/1/data", :method => :get },
          { :controller => "api/traces/data", :action => "show", :trace_id => "1" }
        )
        assert_routing(
          { :path => "/api/0.6/gpx/1/data.xml", :method => :get },
          { :controller => "api/traces/data", :action => "show", :trace_id => "1", :format => "xml" }
        )
      end

      # Test downloading a trace through the api
      def test_show
        public_trace_file = create(:trace, :visibility => "public", :fixture => "a")

        # First with no auth
        get api_trace_data_path(public_trace_file)
        assert_response :unauthorized

        # Now with some other user, which should work since the trace is public
        auth_header = bearer_authorization_header
        get api_trace_data_path(public_trace_file), :headers => auth_header
        follow_redirect!
        follow_redirect!
        check_trace_data public_trace_file, "848caa72f2f456d1bd6a0fdf228aa1b9"

        # And finally we should be able to do it with the owner of the trace
        auth_header = bearer_authorization_header public_trace_file.user
        get api_trace_data_path(public_trace_file), :headers => auth_header
        follow_redirect!
        follow_redirect!
        check_trace_data public_trace_file, "848caa72f2f456d1bd6a0fdf228aa1b9"
      end

      # Test downloading a compressed trace through the api
      def test_data_compressed
        identifiable_trace_file = create(:trace, :visibility => "identifiable", :fixture => "d")

        # Authenticate as the owner of the trace we will be using
        auth_header = bearer_authorization_header identifiable_trace_file.user

        # First get the data as is
        get api_trace_data_path(identifiable_trace_file), :headers => auth_header
        follow_redirect!
        follow_redirect!
        check_trace_data identifiable_trace_file, "c6422a3d8750faae49ed70e7e8a51b93", "application/gzip", "gpx.gz"

        # Now ask explicitly for XML format
        get api_trace_data_path(identifiable_trace_file, :format => "xml"), :headers => auth_header
        check_trace_data identifiable_trace_file, "abd6675fdf3024a84fc0a1deac147c0d", "application/xml", "xml"

        # Now ask explicitly for GPX format
        get api_trace_data_path(identifiable_trace_file, :format => "gpx"), :headers => auth_header
        check_trace_data identifiable_trace_file, "abd6675fdf3024a84fc0a1deac147c0d"
      end

      # Check an anonymous trace can't be downloaded by another user through the api
      def test_data_anon
        anon_trace_file = create(:trace, :visibility => "private", :fixture => "b")

        # First with no auth
        get api_trace_data_path(anon_trace_file)
        assert_response :unauthorized

        # Now with some other user, which shouldn't work since the trace is anon
        auth_header = bearer_authorization_header
        get api_trace_data_path(anon_trace_file), :headers => auth_header
        assert_response :forbidden

        # And finally we should be able to do it with the owner of the trace
        auth_header = bearer_authorization_header anon_trace_file.user
        get api_trace_data_path(anon_trace_file), :headers => auth_header
        follow_redirect!
        follow_redirect!
        check_trace_data anon_trace_file, "db4cb5ed2d7d2b627b3b504296c4f701"
      end

      # Test downloading a trace that doesn't exist through the api
      def test_data_not_found
        deleted_trace_file = create(:trace, :deleted)

        # Try first with no auth, as it should require it
        get api_trace_data_path(0)
        assert_response :unauthorized

        # Login, and try again
        auth_header = bearer_authorization_header
        get api_trace_data_path(0), :headers => auth_header
        assert_response :not_found

        # Now try a trace which did exist but has been deleted
        auth_header = bearer_authorization_header deleted_trace_file.user
        get api_trace_data_path(deleted_trace_file), :headers => auth_header
        assert_response :not_found
      end

      private

      def check_trace_data(trace, digest, content_type = "application/gpx+xml", extension = "gpx")
        assert_response :success
        assert_equal digest, Digest::MD5.hexdigest(response.body)
        assert_equal content_type, response.media_type
        assert_equal "attachment; filename=\"#{trace.id}.#{extension}\"; filename*=UTF-8''#{trace.id}.#{extension}", @response.header["Content-Disposition"]
      end
    end
  end
end
