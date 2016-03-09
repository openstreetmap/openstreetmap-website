require "test_helper"

class TraceControllerTest < ActionController::TestCase
  fixtures :users, :user_preferences, :gpx_files
  set_fixture_class :gpx_files => Trace

  def setup
    @gpx_trace_dir = Object.send("remove_const", "GPX_TRACE_DIR")
    Object.const_set("GPX_TRACE_DIR", File.dirname(__FILE__) + "/../traces")

    @gpx_image_dir = Object.send("remove_const", "GPX_IMAGE_DIR")
    Object.const_set("GPX_IMAGE_DIR", File.dirname(__FILE__) + "/../traces")
  end

  def teardown
    Object.send("remove_const", "GPX_TRACE_DIR")
    Object.const_set("GPX_TRACE_DIR", @gpx_trace_dir)

    Object.send("remove_const", "GPX_IMAGE_DIR")
    Object.const_set("GPX_IMAGE_DIR", @gpx_image_dir)
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
    # First with the public list
    get :list
    check_trace_list Trace.visible_to_all

    # Restrict traces to those with a given tag
    get :list, :tag => "London"
    check_trace_list Trace.tagged("London").visible_to_all

    # Should see more when we are logged in
    get :list, {}, { :user => users(:public_user).id }
    check_trace_list Trace.visible_to(users(:public_user).id)

    # Again, we should see more when we are logged in
    get :list, { :tag => "London" }, { :user => users(:public_user).id }
    check_trace_list Trace.tagged("London").visible_to(users(:public_user).id)
  end

  # Check that I can get mine
  def test_list_mine
    # First try to get it when not logged in
    get :mine
    assert_redirected_to :controller => "user", :action => "login", :referer => "/traces/mine"

    # Now try when logged in
    get :mine, {}, { :user => users(:public_user).id }
    assert_redirected_to :controller => "trace", :action => "list", :display_name => users(:public_user).display_name

    # Fetch the actual list
    get :list, { :display_name => users(:public_user).display_name }, { :user => users(:public_user).id }
    check_trace_list users(:public_user).traces
  end

  # Check the list of changesets for a specific user
  def test_list_user
    # Test a user with no traces
    get :list, :display_name => users(:second_public_user).display_name
    check_trace_list users(:second_public_user).traces.visible_to_all

    # Test a user with some traces - should see only public ones
    get :list, :display_name => users(:public_user).display_name
    check_trace_list users(:public_user).traces.visible_to_all

    # Should still see only public ones when authenticated as another user
    get :list, { :display_name => users(:public_user).display_name }, { :user => users(:normal_user).id }
    check_trace_list users(:public_user).traces.visible_to_all

    # Should see all traces when authenticated as the target user
    get :list, { :display_name => users(:public_user).display_name }, { :user => users(:public_user).id }
    check_trace_list users(:public_user).traces

    # Should only see traces with the correct tag when a tag is specified
    get :list, { :display_name => users(:public_user).display_name, :tag => "London" }, { :user => users(:public_user).id }
    check_trace_list users(:public_user).traces.tagged("London")

    # Should get an error if the user does not exist
    get :list, :display_name => "UnknownUser"
    assert_response :not_found
    assert_template "user/no_such_user"
  end

  # Check that the rss loads
  def test_rss
    # First with the public feed
    get :georss, :format => :rss
    check_trace_feed Trace.visible_to_all

    # Restrict traces to those with a given tag
    get :georss, :tag => "London", :format => :rss
    check_trace_feed Trace.tagged("London").visible_to_all

    # Restrict traces to those for a given user
    get :georss, :display_name => users(:public_user).display_name, :format => :rss
    check_trace_feed users(:public_user).traces.visible_to_all

    # Restrict traces to those for a given user with a tiven tag
    get :georss, :display_name => users(:public_user).display_name, :tag => "Birmingham", :format => :rss
    check_trace_feed users(:public_user).traces.tagged("Birmingham").visible_to_all
  end

  # Test viewing a trace
  def test_view
    # First with no auth, which should work since the trace is public
    get :view, :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id
    check_trace_view gpx_files(:public_trace_file)

    # Now with some other user, which should work since the trace is public
    get :view, { :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id }, { :user => users(:public_user).id }
    check_trace_view gpx_files(:public_trace_file)

    # And finally we should be able to do it with the owner of the trace
    get :view, { :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id }, { :user => users(:normal_user).id }
    check_trace_view gpx_files(:public_trace_file)
  end

  # Check an anonymous trace can't be viewed by another user
  def test_view_anon
    # First with no auth
    get :view, :display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id
    assert_response :redirect
    assert_redirected_to :action => :list

    # Now with some other user, which should work since the trace is anon
    get :view, { :display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id }, { :user => users(:normal_user).id }
    assert_response :redirect
    assert_redirected_to :action => :list

    # And finally we should be able to do it with the owner of the trace
    get :view, { :display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id }, { :user => users(:public_user).id }
    check_trace_view gpx_files(:anon_trace_file)
  end

  # Test viewing a trace that doesn't exist
  def test_view_not_found
    # First with no auth, which should work since the trace is public
    get :view, :display_name => users(:public_user).display_name, :id => 0
    assert_response :redirect
    assert_redirected_to :action => :list

    # Now with some other user, which should work since the trace is public
    get :view, { :display_name => users(:public_user).display_name, :id => 0 }, { :user => users(:public_user).id }
    assert_response :redirect
    assert_redirected_to :action => :list

    # And finally we should be able to do it with the owner of the trace
    get :view, { :display_name => users(:public_user).display_name, :id => 5 }, { :user => users(:public_user).id }
    assert_response :redirect
    assert_redirected_to :action => :list
  end

  # Test downloading a trace
  def test_data
    # First with no auth, which should work since the trace is public
    get :data, :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id
    check_trace_data gpx_files(:public_trace_file)

    # Now with some other user, which should work since the trace is public
    get :data, { :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id }, { :user => users(:public_user).id }
    check_trace_data gpx_files(:public_trace_file)

    # And finally we should be able to do it with the owner of the trace
    get :data, { :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id }, { :user => users(:normal_user).id }
    check_trace_data gpx_files(:public_trace_file)
  end

  # Test downloading a compressed trace
  def test_data_compressed
    # First get the data as is
    get :data, :display_name => users(:public_user).display_name, :id => gpx_files(:identifiable_trace_file).id
    check_trace_data gpx_files(:identifiable_trace_file), "application/x-gzip", "gpx.gz"

    # Now ask explicitly for XML format
    get :data, :display_name => users(:public_user).display_name, :id => gpx_files(:identifiable_trace_file).id, :format => "xml"
    check_trace_data gpx_files(:identifiable_trace_file), "application/xml", "xml"

    # Now ask explicitly for GPX format
    get :data, :display_name => users(:public_user).display_name, :id => gpx_files(:identifiable_trace_file).id, :format => "gpx"
    check_trace_data gpx_files(:identifiable_trace_file)
  end

  # Check an anonymous trace can't be downloaded by another user
  def test_data_anon
    # First with no auth
    get :data, :display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id
    assert_response :not_found

    # Now with some other user, which shouldn't work since the trace is anon
    get :data, { :display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id }, { :user => users(:normal_user).id }
    assert_response :not_found

    # And finally we should be able to do it with the owner of the trace
    get :data, { :display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id }, { :user => users(:public_user).id }
    check_trace_data gpx_files(:anon_trace_file)
  end

  # Test downloading a trace that doesn't exist
  def test_data_not_found
    # First with no auth and a trace that has never existed
    get :data, :display_name => users(:public_user).display_name, :id => 0
    assert_response :not_found

    # Now with a trace that has never existed
    get :data, { :display_name => users(:public_user).display_name, :id => 0 }, { :user => users(:public_user).id }
    assert_response :not_found

    # Now with a trace that has been deleted
    get :data, { :display_name => users(:public_user).display_name, :id => 5 }, { :user => users(:public_user).id }
    assert_response :not_found
  end

  # Test downloading the picture for a trace
  def test_picture
    # First with no auth, which should work since the trace is public
    get :picture, :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id
    check_trace_picture gpx_files(:public_trace_file)

    # Now with some other user, which should work since the trace is public
    get :picture, { :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id }, { :user => users(:public_user).id }
    check_trace_picture gpx_files(:public_trace_file)

    # And finally we should be able to do it with the owner of the trace
    get :picture, { :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id }, { :user => users(:normal_user).id }
    check_trace_picture gpx_files(:public_trace_file)
  end

  # Check the picture for an anonymous trace can't be downloaded by another user
  def test_picture_anon
    # First with no auth
    get :picture, :display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id
    assert_response :forbidden

    # Now with some other user, which shouldn't work since the trace is anon
    get :picture, { :display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id }, { :user => users(:normal_user).id }
    assert_response :forbidden

    # And finally we should be able to do it with the owner of the trace
    get :picture, { :display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id }, { :user => users(:public_user).id }
    check_trace_picture gpx_files(:anon_trace_file)
  end

  # Test downloading the picture for a trace that doesn't exist
  def test_picture_not_found
    # First with no auth, which should work since the trace is public
    get :picture, :display_name => users(:public_user).display_name, :id => 0
    assert_response :not_found

    # Now with some other user, which should work since the trace is public
    get :picture, { :display_name => users(:public_user).display_name, :id => 0 }, { :user => users(:public_user).id }
    assert_response :not_found

    # And finally we should be able to do it with the owner of the trace
    get :picture, { :display_name => users(:public_user).display_name, :id => 5 }, { :user => users(:public_user).id }
    assert_response :not_found
  end

  # Test downloading the icon for a trace
  def test_icon
    # First with no auth, which should work since the trace is public
    get :icon, :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id
    check_trace_icon gpx_files(:public_trace_file)

    # Now with some other user, which should work since the trace is public
    get :icon, { :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id }, { :user => users(:public_user).id }
    check_trace_icon gpx_files(:public_trace_file)

    # And finally we should be able to do it with the owner of the trace
    get :icon, { :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id }, { :user => users(:normal_user).id }
    check_trace_icon gpx_files(:public_trace_file)
  end

  # Check the icon for an anonymous trace can't be downloaded by another user
  def test_icon_anon
    # First with no auth
    get :icon, :display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id
    assert_response :forbidden

    # Now with some other user, which shouldn't work since the trace is anon
    get :icon, { :display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id }, { :user => users(:normal_user).id }
    assert_response :forbidden

    # And finally we should be able to do it with the owner of the trace
    get :icon, { :display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id }, { :user => users(:public_user).id }
    check_trace_icon gpx_files(:anon_trace_file)
  end

  # Test downloading the icon for a trace that doesn't exist
  def test_icon_not_found
    # First with no auth, which should work since the trace is public
    get :icon, :display_name => users(:public_user).display_name, :id => 0
    assert_response :not_found

    # Now with some other user, which should work since the trace is public
    get :icon, { :display_name => users(:public_user).display_name, :id => 0 }, { :user => users(:public_user).id }
    assert_response :not_found

    # And finally we should be able to do it with the owner of the trace
    get :icon, { :display_name => users(:public_user).display_name, :id => 5 }, { :user => users(:public_user).id }
    assert_response :not_found
  end

  # Test fetching the create page
  def test_create_get
    # First with no auth
    get :create
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :referer => trace_create_path

    # Now authenticated as a user with gps.trace.visibility set
    get :create, {}, { :user => users(:public_user).id }
    assert_response :success
    assert_template :create
    assert_select "select#trace_visibility option[value=identifiable][selected]", 1

    # Now authenticated as a user with gps.trace.public set
    get :create, {}, { :user => users(:second_public_user).id }
    assert_response :success
    assert_template :create
    assert_select "select#trace_visibility option[value=public][selected]", 1

    # Now authenticated as a user with no preferences
    get :create, {}, { :user => users(:normal_user).id }
    assert_response :success
    assert_template :create
    assert_select "select#trace_visibility option[value=private][selected]", 1
  end

  # Test creating a trace
  def test_create_post
    # Get file to use
    file = Rack::Test::UploadedFile.new(gpx_files(:public_trace_file).trace_name, "application/gpx+xml")

    # First with no auth
    post :create, :trace => { :gpx_file => file, :description => "New Trace", :tagstring => "new,trace", :visibility => "trackable" }
    assert_response :forbidden

    # Now authenticated
    assert_not_equal "trackable", users(:public_user).preferences.where(:k => "gps.trace.visibility").first.v
    post :create, { :trace => { :gpx_file => file, :description => "New Trace", :tagstring => "new,trace", :visibility => "trackable" } }, { :user => users(:public_user).id }
    assert_response :redirect
    assert_redirected_to :action => :list, :display_name => users(:public_user).display_name
    assert_match /file has been uploaded/, flash[:notice]
    trace = Trace.order(:id => :desc).first
    assert_equal "1.gpx", trace.name
    assert_equal "New Trace", trace.description
    assert_equal %w(new trace), trace.tags.order(:tag).collect(&:tag)
    assert_equal "trackable", trace.visibility
    assert_equal false, trace.inserted
    assert_equal File.new(gpx_files(:public_trace_file).trace_name).read, File.new(trace.trace_name).read
    trace.destroy
    assert_equal "trackable", users(:public_user).preferences.where(:k => "gps.trace.visibility").first.v
  end

  # Test fetching the edit page for a trace
  def test_edit_get
    # First with no auth
    get :edit, :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :referer => trace_edit_path(:display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id)

    # Now with some other user, which should fail
    get :edit, { :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id }, { :user => users(:public_user).id }
    assert_response :forbidden

    # Now with a trace which doesn't exist
    get :edit, { :display_name => users(:public_user).display_name, :id => 0 }, { :user => users(:public_user).id }
    assert_response :not_found

    # Now with a trace which has been deleted
    get :edit, { :display_name => users(:public_user).display_name, :id => gpx_files(:deleted_trace_file).id }, { :user => users(:public_user).id }
    assert_response :not_found

    # Finally with a trace that we are allowed to edit
    get :edit, { :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id }, { :user => users(:normal_user).id }
    assert_response :success
  end

  # Test saving edits to a trace
  def test_edit_post
    # New details
    new_details = { :description => "Changed description", :tagstring => "new_tag", :visibility => "private" }

    # First with no auth
    post :edit, :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id, :trace => new_details
    assert_response :forbidden

    # Now with some other user, which should fail
    post :edit, { :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id, :trace => new_details }, { :user => users(:public_user).id }
    assert_response :forbidden

    # Now with a trace which doesn't exist
    post :edit, { :display_name => users(:public_user).display_name, :id => 0 }, { :user => users(:public_user).id, :trace => new_details }
    assert_response :not_found

    # Now with a trace which has been deleted
    post :edit, { :display_name => users(:public_user).display_name, :id => gpx_files(:deleted_trace_file).id, :trace => new_details }, { :user => users(:public_user).id }
    assert_response :not_found

    # Finally with a trace that we are allowed to edit
    post :edit, { :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id, :trace => new_details }, { :user => users(:normal_user).id }
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
    post :delete, :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id
    assert_response :forbidden

    # Now with some other user, which should fail
    post :delete, { :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id }, { :user => users(:public_user).id }
    assert_response :forbidden

    # Now with a trace which doesn't exist
    post :delete, { :display_name => users(:public_user).display_name, :id => 0 }, { :user => users(:public_user).id }
    assert_response :not_found

    # Now with a trace has already been deleted
    post :delete, { :display_name => users(:public_user).display_name, :id => gpx_files(:deleted_trace_file).id }, { :user => users(:public_user).id }
    assert_response :not_found

    # Finally with a trace that we are allowed to delete
    post :delete, { :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id }, { :user => users(:normal_user).id }
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

  # Test downloading a trace through the api
  def test_api_data
    # First with no auth
    get :api_data, :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id
    assert_response :unauthorized

    # Now with some other user, which should work since the trace is public
    basic_authorization(users(:public_user).display_name, "test")
    get :api_data, :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id
    check_trace_data gpx_files(:public_trace_file)

    # And finally we should be able to do it with the owner of the trace
    basic_authorization(users(:normal_user).display_name, "test")
    get :api_data, :display_name => users(:normal_user).display_name, :id => gpx_files(:public_trace_file).id
    check_trace_data gpx_files(:public_trace_file)
  end

  # Test downloading a compressed trace through the api
  def test_api_data_compressed
    # Authenticate as the owner of the trace we will be using
    basic_authorization(users(:public_user).display_name, "test")

    # First get the data as is
    get :api_data, :display_name => users(:public_user).display_name, :id => gpx_files(:identifiable_trace_file).id
    check_trace_data gpx_files(:identifiable_trace_file), "application/x-gzip", "gpx.gz"

    # Now ask explicitly for XML format
    get :api_data, :display_name => users(:public_user).display_name, :id => gpx_files(:identifiable_trace_file).id, :format => "xml"
    check_trace_data gpx_files(:identifiable_trace_file), "application/xml", "xml"

    # Now ask explicitly for GPX format
    get :api_data, :display_name => users(:public_user).display_name, :id => gpx_files(:identifiable_trace_file).id, :format => "gpx"
    check_trace_data gpx_files(:identifiable_trace_file)
  end

  # Check an anonymous trace can't be downloaded by another user through the api
  def test_api_data_anon
    # First with no auth
    get :api_data, :display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id
    assert_response :unauthorized

    # Now with some other user, which shouldn't work since the trace is anon
    basic_authorization(users(:normal_user).display_name, "test")
    get :api_data, :display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id
    assert_response :forbidden

    # And finally we should be able to do it with the owner of the trace
    basic_authorization(users(:public_user).display_name, "test")
    get :api_data, :display_name => users(:public_user).display_name, :id => gpx_files(:anon_trace_file).id
    check_trace_data gpx_files(:anon_trace_file)
  end

  # Test downloading a trace that doesn't exist through the api
  def test_api_data_not_found
    # First with no auth
    get :api_data, :display_name => users(:public_user).display_name, :id => 0
    assert_response :unauthorized

    # Now with a trace that has never existed
    basic_authorization(users(:public_user).display_name, "test")
    get :api_data, :display_name => users(:public_user).display_name, :id => 0
    assert_response :not_found

    # Now with a trace that has been deleted
    basic_authorization(users(:public_user).display_name, "test")
    get :api_data, :display_name => users(:public_user).display_name, :id => 5
    assert_response :not_found
  end

  # Test creating a trace through the api
  def test_api_create
    # Get file to use
    file = Rack::Test::UploadedFile.new(gpx_files(:public_trace_file).trace_name, "application/gpx+xml")

    # First with no auth
    post :api_create, :file => file, :description => "New Trace", :tags => "new,trace", :visibility => "trackable"
    assert_response :unauthorized

    # Now authenticated
    assert_not_equal "trackable", users(:public_user).preferences.where(:k => "gps.trace.visibility").first.v
    basic_authorization(users(:public_user).display_name, "test")
    post :api_create, :file => file, :description => "New Trace", :tags => "new,trace", :visibility => "trackable"
    assert_response :success
    trace = Trace.find(response.body.to_i)
    assert_equal "1.gpx", trace.name
    assert_equal "New Trace", trace.description
    assert_equal %w(new trace), trace.tags.order(:tag).collect(&:tag)
    assert_equal "trackable", trace.visibility
    assert_equal false, trace.inserted
    assert_equal File.new(gpx_files(:public_trace_file).trace_name).read, File.new(trace.trace_name).read
    trace.destroy
    assert_equal "trackable", users(:public_user).preferences.where(:k => "gps.trace.visibility").first.v

    # Rewind the file
    file.rewind

    # Now authenticated, with the legacy public flag
    assert_not_equal "public", users(:public_user).preferences.where(:k => "gps.trace.visibility").first.v
    basic_authorization(users(:public_user).display_name, "test")
    post :api_create, :file => file, :description => "New Trace", :tags => "new,trace", :public => 1
    assert_response :success
    trace = Trace.find(response.body.to_i)
    assert_equal "1.gpx", trace.name
    assert_equal "New Trace", trace.description
    assert_equal %w(new trace), trace.tags.order(:tag).collect(&:tag)
    assert_equal "public", trace.visibility
    assert_equal false, trace.inserted
    assert_equal File.new(gpx_files(:public_trace_file).trace_name).read, File.new(trace.trace_name).read
    trace.destroy
    assert_equal "public", users(:public_user).preferences.where(:k => "gps.trace.visibility").first.v

    # Rewind the file
    file.rewind

    # Now authenticated, with the legacy private flag
    assert_nil users(:second_public_user).preferences.where(:k => "gps.trace.visibility").first
    basic_authorization(users(:second_public_user).display_name, "test")
    post :api_create, :file => file, :description => "New Trace", :tags => "new,trace", :public => 0
    assert_response :success
    trace = Trace.find(response.body.to_i)
    assert_equal "1.gpx", trace.name
    assert_equal "New Trace", trace.description
    assert_equal %w(new trace), trace.tags.order(:tag).collect(&:tag)
    assert_equal "private", trace.visibility
    assert_equal false, trace.inserted
    assert_equal File.new(gpx_files(:public_trace_file).trace_name).read, File.new(trace.trace_name).read
    trace.destroy
    assert_equal "private", users(:second_public_user).preferences.where(:k => "gps.trace.visibility").first.v
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
          traces.visible.order("timestamp DESC").zip(items).each do |trace, item|
            assert_select item, "title", trace.name
            assert_select item, "link", "http://test.host/user/#{trace.user.display_name}/traces/#{trace.id}"
            assert_select item, "guid", "http://test.host/user/#{trace.user.display_name}/traces/#{trace.id}"
            assert_select item, "description"
            # assert_select item, "dc:creator", trace.user.display_name
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
          traces.visible.order("timestamp DESC").zip(rows).each do |trace, row|
            assert_select row, "a", Regexp.new(Regexp.escape(trace.name))
            assert_select row, "span.trace_summary", Regexp.new(Regexp.escape("(#{trace.size} points)")) if trace.inserted?
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
    assert_equal content_type, response.content_type
    assert_equal "attachment; filename=\"#{trace.id}.#{extension}\"", @response.header["Content-Disposition"]
  end

  def check_trace_picture(trace)
    assert_response :success
    assert_equal "image/gif", response.content_type
    assert_equal trace.large_picture, response.body
  end

  def check_trace_icon(trace)
    assert_response :success
    assert_equal "image/gif", response.content_type
    assert_equal trace.icon_picture, response.body
  end
end
