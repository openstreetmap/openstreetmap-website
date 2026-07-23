# frozen_string_literal: true

require "test_helper"

module Traces
  class DataControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/traces/1/data", :method => :get },
        { :controller => "traces/data", :action => "show", :trace_id => "1" }
      )
      assert_routing(
        { :path => "/traces/1/data.xml", :method => :get },
        { :controller => "traces/data", :action => "show", :trace_id => "1", :format => "xml" }
      )

      get "/trace/1/data"
      assert_redirected_to "/traces/1/data"

      get "/trace/1/data.xml"
      assert_redirected_to "/traces/1/data.xml"
    end

    # Test downloading a trace
    def test_show
      public_trace_file = create(:trace, :visibility => "public", :fixture => "a")

      # First with no auth, which should work since the trace is public
      get trace_data_path(public_trace_file)
      check_trace_data public_trace_file, "848caa72f2f456d1bd6a0fdf228aa1b9"

      # Now with some other user, which should work since the trace is public
      session_for(create(:user))
      get trace_data_path(public_trace_file)
      check_trace_data public_trace_file, "848caa72f2f456d1bd6a0fdf228aa1b9"

      # And finally we should be able to do it with the owner of the trace
      session_for(public_trace_file.user)
      get trace_data_path(public_trace_file)
      check_trace_data public_trace_file, "848caa72f2f456d1bd6a0fdf228aa1b9"
    end

    # A trace uploaded before GpxS3 was enabled is stored gzipped but has no
    # gzip_content_encoding flag, so the server must unzip it even when the
    # client accepts gzip.
    def test_show_gzipped_by_server_without_store_header
      public_trace_file = create(:trace, :visibility => "identifiable", :fixture => "a")

      get trace_data_path(public_trace_file), :headers => { "Accept-Encoding" => "gzip" }

      check_trace_data public_trace_file, "848caa72f2f456d1bd6a0fdf228aa1b9"
      assert_includes response.headers["Vary"].to_s, "Accept-Encoding"
    end

    # A trace stored with a Content-Encoding: gzip header goes out as a
    # redirect when the client accepts gzip, and the server unzips it when
    # the client doesn't.
    def test_show_gzipped_by_server_with_store_header
      public_trace_file = create(:trace, :visibility => "identifiable", :fixture => "a")
      blob = public_trace_file.file.blob
      blob.update!(:custom_metadata => blob.custom_metadata.merge("gzip_content_encoding" => true))

      get trace_data_path(public_trace_file), :headers => { "Accept-Encoding" => "gzip" }
      assert_response :redirect

      get trace_data_path(public_trace_file), :headers => { "Accept-Encoding" => "identity" }
      check_trace_data public_trace_file, "848caa72f2f456d1bd6a0fdf228aa1b9"
    end

    # Test downloading a compressed trace
    def test_show_compressed
      identifiable_trace_file = create(:trace, :visibility => "identifiable", :fixture => "d")

      # First get the data as is
      get trace_data_path(identifiable_trace_file)
      follow_redirect!
      follow_redirect!
      check_trace_data identifiable_trace_file, "c6422a3d8750faae49ed70e7e8a51b93", "application/gzip", "gpx.gz"

      # Now ask explicitly for XML format
      get trace_data_path(identifiable_trace_file, :format => "xml")
      check_trace_data identifiable_trace_file, "abd6675fdf3024a84fc0a1deac147c0d", "application/xml", "xml"

      # Now ask explicitly for GPX format
      get trace_data_path(identifiable_trace_file, :format => "gpx")
      check_trace_data identifiable_trace_file, "abd6675fdf3024a84fc0a1deac147c0d"
    end

    # Check an anonymous trace can't be downloaded by another user
    def test_show_anon
      anon_trace_file = create(:trace, :visibility => "private", :fixture => "b")

      # First with no auth
      get trace_data_path(anon_trace_file)
      assert_response :not_found

      # Now with some other user, which shouldn't work since the trace is anon
      session_for(create(:user))
      get trace_data_path(anon_trace_file)
      assert_response :not_found

      # And finally we should be able to do it with the owner of the trace
      session_for(anon_trace_file.user)
      get trace_data_path(anon_trace_file)
      check_trace_data anon_trace_file, "db4cb5ed2d7d2b627b3b504296c4f701"
    end

    # Test downloading a trace that doesn't exist
    def test_show_not_found
      deleted_trace_file = create(:trace, :deleted)

      # First with a trace that has never existed
      get trace_data_path(0)
      assert_response :not_found

      # Now with a trace that has been deleted
      session_for(deleted_trace_file.user)
      get trace_data_path(deleted_trace_file)
      assert_response :not_found
    end

    def test_show_offline
      public_trace_file = create(:trace, :visibility => "public", :fixture => "a")
      with_settings(:status => "gpx_offline") do
        get trace_data_path(public_trace_file)
        assert_response :success
        assert_template :offline
      end
    end

    # Check that trace data can't be downloaded when the traces feature is disabled
    def test_show_disabled
      public_trace_file = create(:trace, :visibility => "public", :fixture => "a")

      with_settings(:traces_disabled => true) do
        get trace_data_path(public_trace_file)
        assert_response :not_found
      end
    end

    private

    def check_trace_data(trace, digest, content_type = "application/gpx+xml", extension = "gpx")
      assert_equal digest, Digest::MD5.hexdigest(response.body)
      assert_equal content_type, response.media_type
      assert_equal "attachment; filename=\"#{trace.id}.#{extension}\"; filename*=UTF-8''#{trace.id}.#{extension}", @response.header["Content-Disposition"]
    end
  end
end
