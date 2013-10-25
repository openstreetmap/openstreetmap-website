require File.dirname(__FILE__) + '/../test_helper'

class TraceControllerTest < ActionController::TestCase
  fixtures :users, :gpx_files
  set_fixture_class :gpx_files => 'Trace'

  def setup
    @gpx_trace_dir = Object.send("remove_const", "GPX_TRACE_DIR")
    Object.const_set("GPX_TRACE_DIR", File.dirname(__FILE__) + "/../traces")
  end

  def teardown
    Object.send("remove_const", "GPX_TRACE_DIR")
    Object.const_set("GPX_TRACE_DIR", @gpx_trace_dir)
  end

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/gpx/create", :method => :post },
      { :controller => "trace", :action => "api_create" }
    )
    assert_routing(
      { :path => "/api/0.6/gpx/1", :method => :get },
      { :controller => "trace", :action => "api_read", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/gpx/1", :method => :put },
      { :controller => "trace", :action => "api_update", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/gpx/1", :method => :delete },
      { :controller => "trace", :action => "api_delete", :id => "1" }
    )
    assert_recognizes(
      { :controller => "trace", :action => "api_read", :id => "1" },
      { :path => "/api/0.6/gpx/1/details", :method => :get }
    )
    assert_routing(
      { :path => "/api/0.6/gpx/1/data", :method => :get },
      { :controller => "trace", :action => "api_data", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/gpx/1/data.xml", :method => :get },
      { :controller => "trace", :action => "api_data", :id => "1", :format => "xml" }
    )

    assert_routing(
      { :path => "/traces", :method => :get },
      { :controller => "trace", :action => "list" }
    )
    assert_routing(
      { :path => "/traces/page/1", :method => :get },
      { :controller => "trace", :action => "list", :page => "1" }
    )
    assert_routing(
      { :path => "/traces/tag/tagname", :method => :get },
      { :controller => "trace", :action => "list", :tag => "tagname" }
    )
    assert_routing(
      { :path => "/traces/tag/tagname/page/1", :method => :get },
      { :controller => "trace", :action => "list", :tag => "tagname", :page => "1" }
    )
    assert_routing(
      { :path => "/user/username/traces", :method => :get },
      { :controller => "trace", :action => "list", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/traces/page/1", :method => :get },
      { :controller => "trace", :action => "list", :display_name => "username", :page => "1" }
    )
    assert_routing(
      { :path => "/user/username/traces/tag/tagname", :method => :get },
      { :controller => "trace", :action => "list", :display_name => "username", :tag => "tagname" }
    )
    assert_routing(
      { :path => "/user/username/traces/tag/tagname/page/1", :method => :get },
      { :controller => "trace", :action => "list", :display_name => "username", :tag => "tagname", :page => "1" }
    )

    assert_routing(
      { :path => "/traces/mine", :method => :get },
      { :controller => "trace", :action => "mine" }
    )
    assert_routing(
      { :path => "/traces/mine/page/1", :method => :get },
      { :controller => "trace", :action => "mine", :page => "1" }
    )
    assert_routing(
      { :path => "/traces/mine/tag/tagname", :method => :get },
      { :controller => "trace", :action => "mine", :tag => "tagname" }
    )
    assert_routing(
      { :path => "/traces/mine/tag/tagname/page/1", :method => :get },
      { :controller => "trace", :action => "mine", :tag => "tagname", :page => "1" }
    )

    assert_routing(
      { :path => "/traces/rss", :method => :get },
      { :controller => "trace", :action => "georss", :format => :rss }
    )
    assert_routing(
      { :path => "/traces/tag/tagname/rss", :method => :get },
      { :controller => "trace", :action => "georss", :tag => "tagname", :format => :rss }
    )
    assert_routing(
      { :path => "/user/username/traces/rss", :method => :get },
      { :controller => "trace", :action => "georss", :display_name => "username", :format => :rss }
    )
    assert_routing(
      { :path => "/user/username/traces/tag/tagname/rss", :method => :get },
      { :controller => "trace", :action => "georss", :display_name => "username", :tag => "tagname", :format => :rss }
    )

    assert_routing(
      { :path => "/user/username/traces/1", :method => :get },
      { :controller => "trace", :action => "view", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/traces/1/picture", :method => :get },
      { :controller => "trace", :action => "picture", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/traces/1/icon", :method => :get },
      { :controller => "trace", :action => "icon", :display_name => "username", :id => "1" }
    )

    assert_routing(
      { :path => "/trace/create", :method => :get },
      { :controller => "trace", :action => "create" }
    )
    assert_routing(
      { :path => "/trace/create", :method => :post },
      { :controller => "trace", :action => "create" }
    )
    assert_routing(
      { :path => "/trace/1/data", :method => :get },
      { :controller => "trace", :action => "data", :id => "1" }
    )
    assert_routing(
      { :path => "/trace/1/data.xml", :method => :get },
      { :controller => "trace", :action => "data", :id => "1", :format => "xml" }
    )
    assert_routing(
      { :path => "/trace/1/edit", :method => :get },
      { :controller => "trace", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/trace/1/edit", :method => :post },
      { :controller => "trace", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/trace/1/edit", :method => :patch },
      { :controller => "trace", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/trace/1/delete", :method => :post },
      { :controller => "trace", :action => "delete", :id => "1" }
    )
  end

  # Check that the list of changesets is displayed
  def test_list
    get :list
    check_trace_list Trace.public

    get :list, :tag => "London"
    check_trace_list Trace.tagged("London").public
  end

  # Check that I can get mine
  def test_list_mine
    @request.cookies["_osm_username"] = users(:public_user).display_name

    # First try to get it when not logged in
    get :mine
    assert_redirected_to :controller => 'user', :action => 'login', :referer => '/traces/mine'

    # Now try when logged in
    get :mine, {}, {:user => users(:public_user).id}
    assert_redirected_to :controller => 'trace', :action => 'list', :display_name => users(:public_user).display_name

    # Fetch the actual list
    get :list, {:display_name => users(:public_user).display_name}, {:user => users(:public_user).id}
    check_trace_list users(:public_user).traces
  end

  # Check the list of changesets for a specific user
  def test_list_user
    # Test a user with no traces
    get :list, :display_name => users(:second_public_user).display_name
    check_trace_list users(:second_public_user).traces.public

    # Test a user with some traces - should see only public ones
    get :list, :display_name => users(:public_user).display_name
    check_trace_list users(:public_user).traces.public

    @request.cookies["_osm_username"] = users(:normal_user).display_name

    # Should still see only public ones when authenticated as another user
    get :list, {:display_name => users(:public_user).display_name}, {:user => users(:normal_user).id}
    check_trace_list users(:public_user).traces.public

    @request.cookies["_osm_username"] = users(:public_user).display_name

    # Should see all traces when authenticated as the target user
    get :list, {:display_name => users(:public_user).display_name}, {:user => users(:public_user).id}
    check_trace_list users(:public_user).traces

    # Should only see traces with the correct tag when a tag is specified
    get :list, {:display_name => users(:public_user).display_name, :tag => "London"}, {:user => users(:public_user).id}
    check_trace_list users(:public_user).traces.tagged("London")
  end

  # Check that the rss loads
  def test_rss
    get :georss, :format => :rss
    check_trace_feed Trace.public

    get :georss, :tag => "London", :format => :rss
    check_trace_feed Trace.tagged("London").public

    get :georss, :display_name => users(:public_user).display_name, :format => :rss
    check_trace_feed users(:public_user).traces.public

    get :georss, :display_name => users(:public_user).display_name, :tag => "Birmingham", :format => :rss
    check_trace_feed users(:public_user).traces.tagged("Birmingham").public
  end

  # Test viewing a trace
  def test_view
    # First with no auth, which should work since the trace is public
    get :view, {:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id}
    check_trace_view gpx_files(:public_trace_file)

    @request.cookies["_osm_username"] = users(:public_user).display_name

    # Now with some other user, which should work since the trace is public
    get :view, {:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id}, {:user => users(:public_user).id}
    check_trace_view gpx_files(:public_trace_file)

    @request.cookies["_osm_username"] = users(:normal_user).display_name

    # And finally we should be able to do it with the owner of the trace
    get :view, {:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id}, {:user => users(:normal_user).id}
    check_trace_view gpx_files(:public_trace_file)
  end

  # Check an anonymous trace can't be viewed by another user
  def test_view_anon
    # First with no auth
    get :view, {:display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id}
    assert_response :redirect
    assert_redirected_to :action => :list

    @request.cookies["_osm_username"] = users(:normal_user).display_name

    # Now with some other user, which should work since the trace is anon
    get :view, {:display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id}, {:user => users(:normal_user).id}
    assert_response :redirect
    assert_redirected_to :action => :list

    @request.cookies["_osm_username"] = users(:public_user).display_name

    # And finally we should be able to do it with the owner of the trace
    get :view, {:display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id}, {:user => users(:public_user).id}
    check_trace_view gpx_files(:anon_trace_file)
  end

  # Test viewing a trace that doesn't exist
  def test_view_not_found
    # First with no auth, which should work since the trace is public
    get :view, {:display_name => users(:public_user).display_name, :id => 0}
    assert_response :redirect
    assert_redirected_to :action => :list

    @request.cookies["_osm_username"] = users(:public_user).display_name

    # Now with some other user, which should work since the trace is public
    get :view, {:display_name => users(:public_user).display_name, :id => 0}, {:user => users(:public_user).id}
    assert_response :redirect
    assert_redirected_to :action => :list

    # And finally we should be able to do it with the owner of the trace
    get :view, {:display_name => users(:public_user).display_name, :id => 5}, {:user => users(:public_user).id}
    assert_response :redirect
    assert_redirected_to :action => :list
  end

  # Test downloading a trace
  def test_data
    # First with no auth, which should work since the trace is public
    get :data, {:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id}
    check_trace_data gpx_files(:public_trace_file)

    @request.cookies["_osm_username"] = users(:public_user).display_name

    # Now with some other user, which should work since the trace is public
    get :data, {:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id}, {:user => users(:public_user).id}
    check_trace_data gpx_files(:public_trace_file)

    @request.cookies["_osm_username"] = users(:normal_user).display_name

    # And finally we should be able to do it with the owner of the trace
    get :data, {:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id}, {:user => users(:normal_user).id}
    check_trace_data gpx_files(:public_trace_file)
  end

  # Test downloading a compressed trace
  def test_data_compressed
    # First get the data as is
    get :data, {:display_name => users(:public_user).display_name, :id => gpx_files(:identifiable_trace_file).id}
    check_trace_data gpx_files(:identifiable_trace_file), "application/x-gzip", "gpx.gz"

    # Now ask explicitly for XML format
    get :data, {:display_name => users(:public_user).display_name, :id => gpx_files(:identifiable_trace_file).id, :format => "xml"}
    check_trace_data gpx_files(:identifiable_trace_file), "application/xml", "xml"

    # Now ask explicitly for GPX format
    get :data, {:display_name => users(:public_user).display_name, :id => gpx_files(:identifiable_trace_file).id, :format => "gpx"}
    check_trace_data gpx_files(:identifiable_trace_file)
  end

  # Check an anonymous trace can't be downloaded by another user
  def test_data_anon
    # First with no auth
    get :data, {:display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id}
    assert_response :not_found

    @request.cookies["_osm_username"] = users(:normal_user).display_name

    # Now with some other user, which should work since the trace is anon
    get :data, {:display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id}, {:user => users(:normal_user).id}
    assert_response :not_found

    @request.cookies["_osm_username"] = users(:public_user).display_name

    # And finally we should be able to do it with the owner of the trace
    get :data, {:display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id}, {:user => users(:public_user).id}
    check_trace_data gpx_files(:anon_trace_file)
  end

  # Test downloading a trace that doesn't exist
  def test_data_not_found
    # First with no auth, which should work since the trace is public
    get :data, {:display_name => users(:public_user).display_name, :id => 0}
    assert_response :not_found

    @request.cookies["_osm_username"] = users(:public_user).display_name

    # Now with some other user, which should work since the trace is public
    get :data, {:display_name => users(:public_user).display_name, :id => 0}, {:user => users(:public_user).id}
    assert_response :not_found

    # And finally we should be able to do it with the owner of the trace
    get :data, {:display_name => users(:public_user).display_name, :id => 5}, {:user => users(:public_user).id}
    assert_response :not_found
  end

  # Test fetching the edit page for a trace
  def test_edit_get
    # First with no auth
    get :edit, {:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id}
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :referer => trace_edit_path(:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id)

    @request.cookies["_osm_username"] = users(:public_user).display_name

    # Now with some other user, which should fail
    get :edit, {:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id}, {:user => users(:public_user).id}
    assert_response :forbidden

    # Now with a trace which doesn't exist
    get :edit, {:display_name => users(:public_user).display_name, :id => 0}, {:user => users(:public_user).id}
    assert_response :not_found

    # Now with a trace which has been deleted
    get :edit, {:display_name => users(:public_user).display_name, :id => gpx_files(:deleted_trace_file).id}, {:user => users(:public_user).id}
    assert_response :not_found

    @request.cookies["_osm_username"] = users(:normal_user).display_name

    # Finally with a trace that we are allowed to edit
    get :edit, {:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id}, {:user => users(:normal_user).id}
    assert_response :success
  end

  # Test saving edits to a trace
  def test_edit_post
    # New details
    new_details = { :description => "Changed description", :tagstring => "new_tag", :visibility => "private" }

    # First with no auth
    post :edit, {:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id, :trace => new_details}
    assert_response :forbidden

    @request.cookies["_osm_username"] = users(:public_user).display_name

    # Now with some other user, which should fail
    post :edit, {:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id, :trace => new_details}, {:user => users(:public_user).id}
    assert_response :forbidden

    # Now with a trace which doesn't exist
    post :edit, {:display_name => users(:public_user).display_name, :id => 0}, {:user => users(:public_user).id, :trace => new_details}
    assert_response :not_found

    # Now with a trace which has been deleted
    post :edit, {:display_name => users(:public_user).display_name, :id => gpx_files(:deleted_trace_file).id, :trace => new_details}, {:user => users(:public_user).id}
    assert_response :not_found

    @request.cookies["_osm_username"] = users(:normal_user).display_name

    # Finally with a trace that we are allowed to edit
    post :edit, {:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id, :trace => new_details}, {:user => users(:normal_user).id}
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => users(:normal_user).display_name
    trace = Trace.find(gpx_files(:public_trace_file).id)
    assert_equal new_details[:description], trace.description
    assert_equal new_details[:tagstring], trace.tagstring
    assert_equal new_details[:visibility], trace.visibility
  end

  # Test deleting a trace
  def test_delete
    # First with no auth
    post :delete, {:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id,}
    assert_response :forbidden

    @request.cookies["_osm_username"] = users(:public_user).display_name

    # Now with some other user, which should fail
    post :delete, {:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id}, {:user => users(:public_user).id}
    assert_response :forbidden

    # Now with a trace which doesn't exist
    post :delete, {:display_name => users(:public_user).display_name, :id => 0}, {:user => users(:public_user).id}
    assert_response :not_found

    # Now with a trace has already been deleted
    post :delete, {:display_name => users(:public_user).display_name, :id => gpx_files(:deleted_trace_file).id}, {:user => users(:public_user).id}
    assert_response :not_found

    @request.cookies["_osm_username"] = users(:normal_user).display_name

    # Finally with a trace that we are allowed to delete
    post :delete, {:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id}, {:user => users(:normal_user).id}
    assert_response :redirect
    assert_redirected_to :action => :list, :display_name => users(:normal_user).display_name
    trace = Trace.find(gpx_files(:public_trace_file).id)
    assert_equal false, trace.visible
  end

  # Check getting a specific trace through the api
  def test_api_read
    # First with no auth
    get :api_read, :id => gpx_files(:public_trace_file).id
    assert_response :unauthorized

    # Now with some other user, which should work since the trace is public
    basic_authorization(users(:public_user).display_name, "test")
    get :api_read, :id => gpx_files(:public_trace_file).id
    assert_response :success

    # And finally we should be able to do it with the owner of the trace
    basic_authorization(users(:normal_user).display_name, "test")
    get :api_read, :id => gpx_files(:public_trace_file).id
    assert_response :success
  end

  # Check an anoymous trace can't be specifically fetched by another user
  def test_api_read_anon
    # Furst with no auth
    get :api_read, :id => gpx_files(:anon_trace_file).id
    assert_response :unauthorized

    # Now try with another user, which shouldn't work since the trace is anon
    basic_authorization(users(:normal_user).display_name, "test")
    get :api_read, :id => gpx_files(:anon_trace_file).id
    assert_response :forbidden

    # And finally we should be able to get the trace details with the trace owner
    basic_authorization(users(:public_user).display_name, "test")
    get :api_read, :id => gpx_files(:anon_trace_file).id
    assert_response :success
  end

  # Check the api details for a trace that doesn't exist
  def test_api_read_not_found
    # Try first with no auth, as it should requure it
    get :api_read, :id => 0
    assert_response :unauthorized

    # Login, and try again
    basic_authorization(users(:public_user).display_name, "test")
    get :api_read, :id => 0
    assert_response :not_found

    # Now try a trace which did exist but has been deleted
    basic_authorization(users(:public_user).display_name, "test")
    get :api_read, :id => 5
    assert_response :not_found
  end

  # Check updating a trace through the api
  def test_api_update
    # First with no auth
    content gpx_files(:public_trace_file).to_xml
    put :api_update, :id => gpx_files(:public_trace_file).id
    assert_response :unauthorized

    # Now with some other user, which should fail
    basic_authorization(users(:public_user).display_name, "test")
    content gpx_files(:public_trace_file).to_xml
    put :api_update, :id => gpx_files(:public_trace_file).id
    assert_response :forbidden

    # Now with a trace which doesn't exist
    basic_authorization(users(:public_user).display_name, "test")
    content gpx_files(:public_trace_file).to_xml
    put :api_update, :id => 0
    assert_response :not_found

    # Now with a trace which did exist but has been deleted
    basic_authorization(users(:public_user).display_name, "test")
    content gpx_files(:deleted_trace_file).to_xml
    put :api_update, :id => gpx_files(:deleted_trace_file).id
    assert_response :not_found

    # Now try an update with the wrong ID
    basic_authorization(users(:normal_user).display_name, "test")
    content gpx_files(:anon_trace_file).to_xml
    put :api_update, :id => gpx_files(:public_trace_file).id
    assert_response :bad_request, 
       "should not be able to update a trace with a different ID from the XML"

    # And finally try an update that should work
    basic_authorization(users(:normal_user).display_name, "test")
    t = gpx_files(:public_trace_file)
    t.description = "Changed description"
    t.visibility = "private"
    content t.to_xml
    put :api_update, :id => t.id
    assert_response :success
    nt = Trace.find(t.id)
    assert_equal nt.description, t.description
    assert_equal nt.visibility, t.visibility
  end

  # Check deleting a trace through the api
  def test_api_delete
    # First with no auth
    delete :api_delete, :id => gpx_files(:public_trace_file).id
    assert_response :unauthorized

    # Now with some other user, which should fail
    basic_authorization(users(:public_user).display_name, "test")
    delete :api_delete, :id => gpx_files(:public_trace_file).id
    assert_response :forbidden

    # Now with a trace which doesn't exist
    basic_authorization(users(:public_user).display_name, "test")
    delete :api_delete, :id => 0
    assert_response :not_found

    # And finally we should be able to do it with the owner of the trace
    basic_authorization(users(:normal_user).display_name, "test")
    delete :api_delete, :id => gpx_files(:public_trace_file).id
    assert_response :success

    # Try it a second time, which should fail
    basic_authorization(users(:normal_user).display_name, "test")
    delete :api_delete, :id => gpx_files(:public_trace_file).id
    assert_response :not_found
  end

private

  def check_trace_feed(traces)
    assert_response :success
    assert_template "georss"
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "title"
        assert_select "description"
        assert_select "link"
        assert_select "image"
        assert_select "item", :count => traces.visible.count do |items|
          traces.visible.order("timestamp DESC").zip(items).each do |trace,item|
            assert_select item, "title", trace.name
            assert_select item, "link", "http://test.host/user/#{trace.user.display_name}/traces/#{trace.id}"
            assert_select item, "guid", "http://test.host/user/#{trace.user.display_name}/traces/#{trace.id}"
            assert_select item, "description"
#            assert_select item, "dc:creator", trace.user.display_name
            assert_select item, "pubDate", trace.timestamp.rfc822
          end
        end
      end
    end
  end

  def check_trace_list(traces)
    assert_response :success
    assert_template "list"

    if traces.count > 0
      assert_select "table#trace_list tbody", :count => 1 do
        assert_select "tr", :count => traces.visible.count do |rows|
          traces.visible.order("timestamp DESC").zip(rows).each do |trace,row|
            assert_select row, "span.trace_summary", Regexp.new(Regexp.escape("(#{trace.size} points)"))
            assert_select row, "td", Regexp.new(Regexp.escape(trace.description))
            assert_select row, "td", Regexp.new(Regexp.escape("by #{trace.user.display_name}"))
          end
        end
      end
    else
      assert_select "h4", /Nothing here yet/
    end
  end

  def check_trace_view(trace)
    assert_response :success
    assert_template "view"

    assert_select "table", :count => 1 do
      assert_select "td", /^#{Regexp.quote(trace.name)} /
      assert_select "td", trace.user.display_name
      assert_select "td", trace.description
    end
  end

  def check_trace_data(trace, content_type = "application/gpx+xml", extension = "gpx")
    assert_response :success
    assert_equal content_type, @response.content_type
    assert_equal "attachment; filename=\"#{trace.id}.#{extension}\"", @response.header["Content-Disposition"]
  end
end
