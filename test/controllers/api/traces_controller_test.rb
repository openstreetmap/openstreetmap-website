require "test_helper"

module Api
  class TracesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/gpx", :method => :post },
        { :controller => "api/traces", :action => "create" }
      )
      assert_recognizes(
        { :controller => "api/traces", :action => "create" },
        { :path => "/api/0.6/gpx/create", :method => :post }
      )
      assert_routing(
        { :path => "/api/0.6/gpx/1", :method => :get },
        { :controller => "api/traces", :action => "show", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/gpx/1", :method => :put },
        { :controller => "api/traces", :action => "update", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/gpx/1", :method => :delete },
        { :controller => "api/traces", :action => "destroy", :id => "1" }
      )
      assert_recognizes(
        { :controller => "api/traces", :action => "show", :id => "1" },
        { :path => "/api/0.6/gpx/1/details", :method => :get }
      )
    end

    # Check getting a specific trace through the api
    def test_show
      public_trace_file = create(:trace, :visibility => "public")

      # First with no auth
      get api_trace_path(public_trace_file)
      assert_response :unauthorized

      # Now with some other user, which should work since the trace is public
      auth_header = bearer_authorization_header
      get api_trace_path(public_trace_file), :headers => auth_header
      assert_response :success

      # And finally we should be able to do it with the owner of the trace
      auth_header = bearer_authorization_header public_trace_file.user
      get api_trace_path(public_trace_file), :headers => auth_header
      assert_response :success
      assert_select "gpx_file[id='#{public_trace_file.id}'][uid='#{public_trace_file.user.id}']", 1
    end

    # Check an anonymous trace can't be specifically fetched by another user
    def test_show_anon
      anon_trace_file = create(:trace, :visibility => "private")

      # First with no auth
      get api_trace_path(anon_trace_file)
      assert_response :unauthorized

      # Now try with another user, which shouldn't work since the trace is anon
      auth_header = bearer_authorization_header
      get api_trace_path(anon_trace_file), :headers => auth_header
      assert_response :forbidden

      # And finally we should be able to get the trace details with the trace owner
      auth_header = bearer_authorization_header anon_trace_file.user
      get api_trace_path(anon_trace_file), :headers => auth_header
      assert_response :success
    end

    # Check the api details for a trace that doesn't exist
    def test_show_not_found
      deleted_trace_file = create(:trace, :deleted)

      # Try first with no auth, as it should require it
      get api_trace_path(:id => 0)
      assert_response :unauthorized

      # Login, and try again
      auth_header = bearer_authorization_header deleted_trace_file.user
      get api_trace_path(:id => 0), :headers => auth_header
      assert_response :not_found

      # Now try a trace which did exist but has been deleted
      auth_header = bearer_authorization_header deleted_trace_file.user
      get api_trace_path(deleted_trace_file), :headers => auth_header
      assert_response :not_found
    end

    # Test creating a trace through the api
    def test_create
      # Get file to use
      fixture = Rails.root.join("test/gpx/fixtures/a.gpx")
      file = Rack::Test::UploadedFile.new(fixture, "application/gpx+xml")
      user = create(:user)

      # First with no auth
      post api_traces_path, :params => { :file => file, :description => "New Trace", :tags => "new,trace", :visibility => "trackable" }
      assert_response :unauthorized

      # Rewind the file
      file.rewind

      # Now authenticated
      create(:user_preference, :user => user, :k => "gps.trace.visibility", :v => "identifiable")
      assert_not_equal "trackable", user.preferences.find_by(:k => "gps.trace.visibility").v

      auth_header = bearer_authorization_header user

      # Create trace and import tracepoints in background job
      perform_enqueued_jobs do
        post api_traces_path, :params => { :file => file, :description => "New Trace", :tags => "new,trace", :visibility => "trackable" }, :headers => auth_header
      end

      assert_response :success

      trace = Trace.find(response.body.to_i)
      assert_equal "a.gpx", trace.name
      assert_equal "New Trace", trace.description
      assert_equal %w[new trace], trace.tags.order(:tag).collect(&:tag)
      assert_equal "trackable", trace.visibility
      assert trace.inserted
      assert_equal File.new(fixture).read, trace.file.blob.download

      # Validate tracepoints
      assert_equal 1, trace.points.size
      tp = trace.points.first
      assert_equal 10000000, tp.latitude
      assert_equal 10000000, tp.longitude
      assert_equal 3221331576, tp.tile
      assert_equal 0, tp.trackid
      assert_in_delta(134.0, tp.altitude)
      assert_equal DateTime.parse("2008-10-01T10:10:10.000Z"), tp.timestamp

      trace.destroy
      assert_equal "trackable", user.preferences.find_by(:k => "gps.trace.visibility").v

      # Rewind the file
      file.rewind

      # Now authenticated, with the legacy public flag
      assert_not_equal "public", user.preferences.find_by(:k => "gps.trace.visibility").v
      auth_header = bearer_authorization_header user
      post api_traces_path, :params => { :file => file, :description => "New Trace", :tags => "new,trace", :public => 1 }, :headers => auth_header
      assert_response :success
      trace = Trace.find(response.body.to_i)
      assert_equal "a.gpx", trace.name
      assert_equal "New Trace", trace.description
      assert_equal %w[new trace], trace.tags.order(:tag).collect(&:tag)
      assert_equal "public", trace.visibility
      assert_not trace.inserted
      assert_equal File.new(fixture).read, trace.file.blob.download
      trace.destroy
      assert_equal "public", user.preferences.find_by(:k => "gps.trace.visibility").v

      # Rewind the file
      file.rewind

      # Now authenticated, with the legacy private flag
      second_user = create(:user)
      assert_nil second_user.preferences.find_by(:k => "gps.trace.visibility")
      auth_header = bearer_authorization_header second_user
      post api_traces_path, :params => { :file => file, :description => "New Trace", :tags => "new,trace", :public => 0 }, :headers => auth_header
      assert_response :success
      trace = Trace.find(response.body.to_i)
      assert_equal "a.gpx", trace.name
      assert_equal "New Trace", trace.description
      assert_equal %w[new trace], trace.tags.order(:tag).collect(&:tag)
      assert_equal "private", trace.visibility
      assert_not trace.inserted
      assert_equal File.new(fixture).read, trace.file.blob.download
      trace.destroy
      assert_equal "private", second_user.preferences.find_by(:k => "gps.trace.visibility").v
    end

    # Check updating a trace through the api
    def test_update
      public_trace_file = create(:trace, :visibility => "public", :fixture => "a")
      deleted_trace_file = create(:trace, :deleted)
      anon_trace_file = create(:trace, :visibility => "private")

      # First with no auth
      put api_trace_path(public_trace_file), :params => create_trace_xml(public_trace_file)
      assert_response :unauthorized

      # Now with some other user, which should fail
      auth_header = bearer_authorization_header
      put api_trace_path(public_trace_file), :params => create_trace_xml(public_trace_file), :headers => auth_header
      assert_response :forbidden

      # Now with a trace which doesn't exist
      auth_header = bearer_authorization_header
      put api_trace_path(:id => 0), :params => create_trace_xml(public_trace_file), :headers => auth_header
      assert_response :not_found

      # Now with a trace which did exist but has been deleted
      auth_header = bearer_authorization_header deleted_trace_file.user
      put api_trace_path(deleted_trace_file), :params => create_trace_xml(deleted_trace_file), :headers => auth_header
      assert_response :not_found

      # Now try an update with the wrong ID
      auth_header = bearer_authorization_header public_trace_file.user
      put api_trace_path(public_trace_file), :params => create_trace_xml(anon_trace_file), :headers => auth_header
      assert_response :bad_request,
                      "should not be able to update a trace with a different ID from the XML"

      # And finally try an update that should work
      auth_header = bearer_authorization_header public_trace_file.user
      t = public_trace_file
      t.description = "Changed description"
      t.visibility = "private"
      put api_trace_path(t), :params => create_trace_xml(t), :headers => auth_header
      assert_response :success
      nt = Trace.find(t.id)
      assert_equal nt.description, t.description
      assert_equal nt.visibility, t.visibility
    end

    # Test that updating a trace doesn't duplicate the tags
    def test_update_tags
      tracetag = create(:tracetag)
      trace = tracetag.trace
      auth_header = bearer_authorization_header trace.user

      put api_trace_path(trace), :params => create_trace_xml(trace), :headers => auth_header
      assert_response :success

      updated = Trace.find(trace.id)
      # Ensure there's only one tag in the database after updating
      assert_equal(1, Tracetag.count)
      # The new tag object might have a different id, so check the string representation
      assert_equal trace.tagstring, updated.tagstring
    end

    # Check deleting a trace through the api
    def test_destroy
      public_trace_file = create(:trace, :visibility => "public")

      # First with no auth
      delete api_trace_path(public_trace_file)
      assert_response :unauthorized

      # Now with some other user, which should fail
      auth_header = bearer_authorization_header
      delete api_trace_path(public_trace_file), :headers => auth_header
      assert_response :forbidden

      # Now with a trace which doesn't exist
      auth_header = bearer_authorization_header
      delete api_trace_path(:id => 0), :headers => auth_header
      assert_response :not_found

      # And finally we should be able to do it with the owner of the trace
      auth_header = bearer_authorization_header public_trace_file.user
      delete api_trace_path(public_trace_file), :headers => auth_header
      assert_response :success

      # Try it a second time, which should fail
      auth_header = bearer_authorization_header public_trace_file.user
      delete api_trace_path(public_trace_file), :headers => auth_header
      assert_response :not_found
    end

    private

    ##
    # build XML for traces
    # this builds a minimum viable XML for the tests in this suite
    def create_trace_xml(trace)
      root = XML::Document.new
      root.root = XML::Node.new "osm"
      trc = XML::Node.new "gpx_file"
      trc["id"] = trace.id.to_s
      trc["visibility"] = trace.visibility
      trc["visible"] = trace.visible.to_s
      desc = XML::Node.new "description"
      desc << trace.description
      trc << desc
      trace.tags.each do |tag|
        t = XML::Node.new "tag"
        t << tag.tag
        trc << t
      end
      root.root << trc
      root.to_s
    end
  end
end
