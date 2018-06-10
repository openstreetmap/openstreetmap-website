require "test_helper"
require "digest"
require "minitest/mock"

class TracesControllerTest < ActionController::TestCase
  def setup
    @gpx_trace_dir = Object.send("remove_const", "GPX_TRACE_DIR")
    Object.const_set("GPX_TRACE_DIR", Rails.root.join("test", "gpx", "traces"))

    @gpx_image_dir = Object.send("remove_const", "GPX_IMAGE_DIR")
    Object.const_set("GPX_IMAGE_DIR", Rails.root.join("test", "gpx", "images"))
  end

  def teardown
    File.unlink(*Dir.glob(File.join(GPX_TRACE_DIR, "*.gpx")))
    File.unlink(*Dir.glob(File.join(GPX_IMAGE_DIR, "*.gif")))

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
      { :controller => "traces", :action => "api_create" }
    )
    assert_routing(
      { :path => "/api/0.6/gpx/1", :method => :get },
      { :controller => "traces", :action => "api_read", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/gpx/1", :method => :put },
      { :controller => "traces", :action => "api_update", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/gpx/1", :method => :delete },
      { :controller => "traces", :action => "api_delete", :id => "1" }
    )
    assert_recognizes(
      { :controller => "traces", :action => "api_read", :id => "1" },
      { :path => "/api/0.6/gpx/1/details", :method => :get }
    )
    assert_routing(
      { :path => "/api/0.6/gpx/1/data", :method => :get },
      { :controller => "traces", :action => "api_data", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/gpx/1/data.xml", :method => :get },
      { :controller => "traces", :action => "api_data", :id => "1", :format => "xml" }
    )

    assert_routing(
      { :path => "/traces", :method => :get },
      { :controller => "traces", :action => "list" }
    )
    assert_routing(
      { :path => "/traces/page/1", :method => :get },
      { :controller => "traces", :action => "list", :page => "1" }
    )
    assert_routing(
      { :path => "/traces/tag/tagname", :method => :get },
      { :controller => "traces", :action => "list", :tag => "tagname" }
    )
    assert_routing(
      { :path => "/traces/tag/tagname/page/1", :method => :get },
      { :controller => "traces", :action => "list", :tag => "tagname", :page => "1" }
    )
    assert_routing(
      { :path => "/user/username/traces", :method => :get },
      { :controller => "traces", :action => "list", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/traces/page/1", :method => :get },
      { :controller => "traces", :action => "list", :display_name => "username", :page => "1" }
    )
    assert_routing(
      { :path => "/user/username/traces/tag/tagname", :method => :get },
      { :controller => "traces", :action => "list", :display_name => "username", :tag => "tagname" }
    )
    assert_routing(
      { :path => "/user/username/traces/tag/tagname/page/1", :method => :get },
      { :controller => "traces", :action => "list", :display_name => "username", :tag => "tagname", :page => "1" }
    )

    assert_routing(
      { :path => "/traces/mine", :method => :get },
      { :controller => "traces", :action => "mine" }
    )
    assert_routing(
      { :path => "/traces/mine/page/1", :method => :get },
      { :controller => "traces", :action => "mine", :page => "1" }
    )
    assert_routing(
      { :path => "/traces/mine/tag/tagname", :method => :get },
      { :controller => "traces", :action => "mine", :tag => "tagname" }
    )
    assert_routing(
      { :path => "/traces/mine/tag/tagname/page/1", :method => :get },
      { :controller => "traces", :action => "mine", :tag => "tagname", :page => "1" }
    )

    assert_routing(
      { :path => "/traces/rss", :method => :get },
      { :controller => "traces", :action => "georss", :format => :rss }
    )
    assert_routing(
      { :path => "/traces/tag/tagname/rss", :method => :get },
      { :controller => "traces", :action => "georss", :tag => "tagname", :format => :rss }
    )
    assert_routing(
      { :path => "/user/username/traces/rss", :method => :get },
      { :controller => "traces", :action => "georss", :display_name => "username", :format => :rss }
    )
    assert_routing(
      { :path => "/user/username/traces/tag/tagname/rss", :method => :get },
      { :controller => "traces", :action => "georss", :display_name => "username", :tag => "tagname", :format => :rss }
    )

    assert_routing(
      { :path => "/user/username/traces/1", :method => :get },
      { :controller => "traces", :action => "view", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/traces/1/picture", :method => :get },
      { :controller => "traces", :action => "picture", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/traces/1/icon", :method => :get },
      { :controller => "traces", :action => "icon", :display_name => "username", :id => "1" }
    )

    assert_routing(
      { :path => "/traces/new", :method => :get },
      { :controller => "traces", :action => "new" }
    )
    assert_routing(
      { :path => "/traces", :method => :post },
      { :controller => "traces", :action => "create" }
    )
    assert_routing(
      { :path => "/trace/1/data", :method => :get },
      { :controller => "traces", :action => "data", :id => "1" }
    )
    assert_routing(
      { :path => "/trace/1/data.xml", :method => :get },
      { :controller => "traces", :action => "data", :id => "1", :format => "xml" }
    )
    assert_routing(
      { :path => "/trace/1/edit", :method => :get },
      { :controller => "traces", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/trace/1/edit", :method => :post },
      { :controller => "traces", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/trace/1/delete", :method => :post },
      { :controller => "traces", :action => "delete", :id => "1" }
    )
  end

  # Check that the list of traces is displayed
  def test_list
    user = create(:user)
    # The fourth test below is surpisingly sensitive to timestamp ordering when the timestamps are equal.
    trace_a = create(:trace, :visibility => "public", :timestamp => 4.seconds.ago) do |trace|
      create(:tracetag, :trace => trace, :tag => "London")
    end
    trace_b = create(:trace, :visibility => "public", :timestamp => 3.seconds.ago) do |trace|
      create(:tracetag, :trace => trace, :tag => "Birmingham")
    end
    trace_c = create(:trace, :visibility => "private", :user => user, :timestamp => 2.seconds.ago) do |trace|
      create(:tracetag, :trace => trace, :tag => "London")
    end
    trace_d = create(:trace, :visibility => "private", :user => user, :timestamp => 1.second.ago) do |trace|
      create(:tracetag, :trace => trace, :tag => "Birmingham")
    end

    # First with the public list
    get :list
    check_trace_list [trace_b, trace_a]

    # Restrict traces to those with a given tag
    get :list, :params => { :tag => "London" }
    check_trace_list [trace_a]

    # Should see more when we are logged in
    get :list, :session => { :user => user }
    check_trace_list [trace_d, trace_c, trace_b, trace_a]

    # Again, we should see more when we are logged in
    get :list, :params => { :tag => "London" }, :session => { :user => user }
    check_trace_list [trace_c, trace_a]
  end

  # Check that I can get mine
  def test_list_mine
    user = create(:user)
    create(:trace, :visibility => "public") do |trace|
      create(:tracetag, :trace => trace, :tag => "Birmingham")
    end
    trace_b = create(:trace, :visibility => "private", :user => user) do |trace|
      create(:tracetag, :trace => trace, :tag => "London")
    end

    # First try to get it when not logged in
    get :mine
    assert_redirected_to :controller => "user", :action => "login", :referer => "/traces/mine"

    # Now try when logged in
    get :mine, :session => { :user => user }
    assert_redirected_to :action => "list", :display_name => user.display_name

    # Fetch the actual list
    get :list, :params => { :display_name => user.display_name }, :session => { :user => user }
    check_trace_list [trace_b]
  end

  # Check the list of traces for a specific user
  def test_list_user
    user = create(:user)
    second_user = create(:user)
    third_user = create(:user)
    create(:trace)
    trace_b = create(:trace, :visibility => "public", :user => user)
    trace_c = create(:trace, :visibility => "private", :user => user) do |trace|
      create(:tracetag, :trace => trace, :tag => "London")
    end

    # Test a user with no traces
    get :list, :params => { :display_name => second_user.display_name }
    check_trace_list []

    # Test the user with the traces - should see only public ones
    get :list, :params => { :display_name => user.display_name }
    check_trace_list [trace_b]

    # Should still see only public ones when authenticated as another user
    get :list, :params => { :display_name => user.display_name }, :session => { :user => third_user }
    check_trace_list [trace_b]

    # Should see all traces when authenticated as the target user
    get :list, :params => { :display_name => user.display_name }, :session => { :user => user }
    check_trace_list [trace_c, trace_b]

    # Should only see traces with the correct tag when a tag is specified
    get :list, :params => { :display_name => user.display_name, :tag => "London" }, :session => { :user => user }
    check_trace_list [trace_c]

    # Should get an error if the user does not exist
    get :list, :params => { :display_name => "UnknownUser" }
    assert_response :not_found
    assert_template "user/no_such_user"
  end

  # Check a multi-page list
  def test_list_paged
    # Create several pages worth of traces
    create_list(:trace, 50)

    # Try and get the list
    get :list
    assert_response :success
    assert_select "table#trace_list tbody", :count => 1 do
      assert_select "tr", :count => 20
    end

    # Try and get the second page
    get :list, :params => { :page => 2 }
    assert_response :success
    assert_select "table#trace_list tbody", :count => 1 do
      assert_select "tr", :count => 20
    end
  end

  # Check that the rss loads
  def test_rss
    user = create(:user)

    # First with the public feed
    get :georss, :params => { :format => :rss }
    check_trace_feed Trace.visible_to_all

    # Restrict traces to those with a given tag
    get :georss, :params => { :tag => "London", :format => :rss }
    check_trace_feed Trace.tagged("London").visible_to_all

    # Restrict traces to those for a given user
    get :georss, :params => { :display_name => user.display_name, :format => :rss }
    check_trace_feed user.traces.visible_to_all

    # Restrict traces to those for a given user with a tiven tag
    get :georss, :params => { :display_name => user.display_name, :tag => "Birmingham", :format => :rss }
    check_trace_feed user.traces.tagged("Birmingham").visible_to_all
  end

  # Test viewing a trace
  def test_view
    public_trace_file = create(:trace, :visibility => "public")

    # First with no auth, which should work since the trace is public
    get :view, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }
    check_trace_view public_trace_file

    # Now with some other user, which should work since the trace is public
    get :view, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }, :session => { :user => create(:user) }
    check_trace_view public_trace_file

    # And finally we should be able to do it with the owner of the trace
    get :view, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }, :session => { :user => public_trace_file.user }
    check_trace_view public_trace_file
  end

  # Check an anonymous trace can't be viewed by another user
  def test_view_anon
    anon_trace_file = create(:trace, :visibility => "private")

    # First with no auth
    get :view, :params => { :display_name => anon_trace_file.user.display_name, :id => anon_trace_file.id }
    assert_response :redirect
    assert_redirected_to :action => :list

    # Now with some other user, which should not work since the trace is anon
    get :view, :params => { :display_name => anon_trace_file.user.display_name, :id => anon_trace_file.id }, :session => { :user => create(:user) }
    assert_response :redirect
    assert_redirected_to :action => :list

    # And finally we should be able to do it with the owner of the trace
    get :view, :params => { :display_name => anon_trace_file.user.display_name, :id => anon_trace_file.id }, :session => { :user => anon_trace_file.user }
    check_trace_view anon_trace_file
  end

  # Test viewing a trace that doesn't exist
  def test_view_not_found
    deleted_trace_file = create(:trace, :deleted)

    # First with a trace that has never existed
    get :view, :params => { :display_name => create(:user).display_name, :id => 0 }
    assert_response :redirect
    assert_redirected_to :action => :list

    # Now with a trace that has been deleted
    get :view, :params => { :display_name => deleted_trace_file.user.display_name, :id => deleted_trace_file.id }, :session => { :user => deleted_trace_file.user }
    assert_response :redirect
    assert_redirected_to :action => :list
  end

  # Test downloading a trace
  def test_data
    public_trace_file = create(:trace, :visibility => "public", :fixture => "a")

    # First with no auth, which should work since the trace is public
    get :data, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }
    check_trace_data public_trace_file, "848caa72f2f456d1bd6a0fdf228aa1b9"

    # Now with some other user, which should work since the trace is public
    get :data, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }, :session => { :user => create(:user) }
    check_trace_data public_trace_file, "848caa72f2f456d1bd6a0fdf228aa1b9"

    # And finally we should be able to do it with the owner of the trace
    get :data, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }, :session => { :user => public_trace_file.user }
    check_trace_data public_trace_file, "848caa72f2f456d1bd6a0fdf228aa1b9"
  end

  # Test downloading a compressed trace
  def test_data_compressed
    identifiable_trace_file = create(:trace, :visibility => "identifiable", :fixture => "d")

    # First get the data as is
    get :data, :params => { :display_name => identifiable_trace_file.user.display_name, :id => identifiable_trace_file.id }
    check_trace_data identifiable_trace_file, "c6422a3d8750faae49ed70e7e8a51b93", "application/x-gzip", "gpx.gz"

    # Now ask explicitly for XML format
    get :data, :params => { :display_name => identifiable_trace_file.user.display_name, :id => identifiable_trace_file.id, :format => "xml" }
    check_trace_data identifiable_trace_file, "abd6675fdf3024a84fc0a1deac147c0d", "application/xml", "xml"

    # Now ask explicitly for GPX format
    get :data, :params => { :display_name => identifiable_trace_file.user.display_name, :id => identifiable_trace_file.id, :format => "gpx" }
    check_trace_data identifiable_trace_file, "abd6675fdf3024a84fc0a1deac147c0d"
  end

  # Check an anonymous trace can't be downloaded by another user
  def test_data_anon
    anon_trace_file = create(:trace, :visibility => "private", :fixture => "b")

    # First with no auth
    get :data, :params => { :display_name => anon_trace_file.user.display_name, :id => anon_trace_file.id }
    assert_response :not_found

    # Now with some other user, which shouldn't work since the trace is anon
    get :data, :params => { :display_name => anon_trace_file.user.display_name, :id => anon_trace_file.id }, :session => { :user => create(:user) }
    assert_response :not_found

    # And finally we should be able to do it with the owner of the trace
    get :data, :params => { :display_name => anon_trace_file.user.display_name, :id => anon_trace_file.id }, :session => { :user => anon_trace_file.user }
    check_trace_data anon_trace_file, "66179ca44f1e93d8df62e2b88cbea732"
  end

  # Test downloading a trace that doesn't exist
  def test_data_not_found
    deleted_trace_file = create(:trace, :deleted)

    # First with a trace that has never existed
    get :data, :params => { :display_name => create(:user).display_name, :id => 0 }
    assert_response :not_found

    # Now with a trace that has been deleted
    get :data, :params => { :display_name => deleted_trace_file.user.display_name, :id => deleted_trace_file.id }, :session => { :user => deleted_trace_file.user }
    assert_response :not_found
  end

  # Test downloading the picture for a trace
  def test_picture
    public_trace_file = create(:trace, :visibility => "public", :fixture => "a")

    # First with no auth, which should work since the trace is public
    get :picture, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }
    check_trace_picture public_trace_file

    # Now with some other user, which should work since the trace is public
    get :picture, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }, :session => { :user => create(:user) }
    check_trace_picture public_trace_file

    # And finally we should be able to do it with the owner of the trace
    get :picture, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }, :session => { :user => public_trace_file.user }
    check_trace_picture public_trace_file
  end

  # Check the picture for an anonymous trace can't be downloaded by another user
  def test_picture_anon
    anon_trace_file = create(:trace, :visibility => "private", :fixture => "b")

    # First with no auth
    get :picture, :params => { :display_name => anon_trace_file.user.display_name, :id => anon_trace_file.id }
    assert_response :forbidden

    # Now with some other user, which shouldn't work since the trace is anon
    get :picture, :params => { :display_name => anon_trace_file.user.display_name, :id => anon_trace_file.id }, :session => { :user => create(:user) }
    assert_response :forbidden

    # And finally we should be able to do it with the owner of the trace
    get :picture, :params => { :display_name => anon_trace_file.user.display_name, :id => anon_trace_file.id }, :session => { :user => anon_trace_file.user }
    check_trace_picture anon_trace_file
  end

  # Test downloading the picture for a trace that doesn't exist
  def test_picture_not_found
    deleted_trace_file = create(:trace, :deleted)

    # First with a trace that has never existed
    get :picture, :params => { :display_name => create(:user).display_name, :id => 0 }
    assert_response :not_found

    # Now with a trace that has been deleted
    get :picture, :params => { :display_name => deleted_trace_file.user.display_name, :id => deleted_trace_file.id }, :session => { :user => deleted_trace_file.user }
    assert_response :not_found
  end

  # Test downloading the icon for a trace
  def test_icon
    public_trace_file = create(:trace, :visibility => "public", :fixture => "a")

    # First with no auth, which should work since the trace is public
    get :icon, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }
    check_trace_icon public_trace_file

    # Now with some other user, which should work since the trace is public
    get :icon, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }, :session => { :user => create(:user) }
    check_trace_icon public_trace_file

    # And finally we should be able to do it with the owner of the trace
    get :icon, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }, :session => { :user => public_trace_file.user }
    check_trace_icon public_trace_file
  end

  # Check the icon for an anonymous trace can't be downloaded by another user
  def test_icon_anon
    anon_trace_file = create(:trace, :visibility => "private", :fixture => "b")

    # First with no auth
    get :icon, :params => { :display_name => anon_trace_file.user.display_name, :id => anon_trace_file.id }
    assert_response :forbidden

    # Now with some other user, which shouldn't work since the trace is anon
    get :icon, :params => { :display_name => anon_trace_file.user.display_name, :id => anon_trace_file.id }, :session => { :user => create(:user) }
    assert_response :forbidden

    # And finally we should be able to do it with the owner of the trace
    get :icon, :params => { :display_name => anon_trace_file.user.display_name, :id => anon_trace_file.id }, :session => { :user => anon_trace_file.user }
    check_trace_icon anon_trace_file
  end

  # Test downloading the icon for a trace that doesn't exist
  def test_icon_not_found
    deleted_trace_file = create(:trace, :deleted)

    # First with a trace that has never existed
    get :icon, :params => { :display_name => create(:user).display_name, :id => 0 }
    assert_response :not_found

    # Now with a trace that has been deleted
    get :icon, :params => { :display_name => deleted_trace_file.user.display_name, :id => deleted_trace_file.id }, :session => { :user => deleted_trace_file.user }
    assert_response :not_found
  end

  # Test fetching the new trace page
  def test_new_get
    # First with no auth
    get :new
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :referer => new_trace_path

    # Now authenticated as a user with gps.trace.visibility set
    user = create(:user)
    create(:user_preference, :user => user, :k => "gps.trace.visibility", :v => "identifiable")
    get :new, :session => { :user => user }
    assert_response :success
    assert_template :new
    assert_select "select#trace_visibility option[value=identifiable][selected]", 1

    # Now authenticated as a user with gps.trace.public set
    second_user = create(:user)
    create(:user_preference, :user => second_user, :k => "gps.trace.public", :v => "default")
    get :new, :session => { :user => second_user }
    assert_response :success
    assert_template :new
    assert_select "select#trace_visibility option[value=public][selected]", 1

    # Now authenticated as a user with no preferences
    third_user = create(:user)
    get :new, :session => { :user => third_user }
    assert_response :success
    assert_template :new
    assert_select "select#trace_visibility option[value=private][selected]", 1
  end

  # Test creating a trace
  def test_create_post
    # Get file to use
    fixture = Rails.root.join("test", "gpx", "fixtures", "a.gpx")
    file = Rack::Test::UploadedFile.new(fixture, "application/gpx+xml")
    user = create(:user)

    # First with no auth
    post :create, :params => { :trace => { :gpx_file => file, :description => "New Trace", :tagstring => "new,trace", :visibility => "trackable" } }
    assert_response :forbidden

    # Rewind the file
    file.rewind

    # Now authenticated
    create(:user_preference, :user => user, :k => "gps.trace.visibility", :v => "identifiable")
    assert_not_equal "trackable", user.preferences.where(:k => "gps.trace.visibility").first.v
    post :create, :params => { :trace => { :gpx_file => file, :description => "New Trace", :tagstring => "new,trace", :visibility => "trackable" } }, :session => { :user => user }
    assert_response :redirect
    assert_redirected_to :action => :list, :display_name => user.display_name
    assert_match /file has been uploaded/, flash[:notice]
    trace = Trace.order(:id => :desc).first
    assert_equal "a.gpx", trace.name
    assert_equal "New Trace", trace.description
    assert_equal %w[new trace], trace.tags.order(:tag).collect(&:tag)
    assert_equal "trackable", trace.visibility
    assert_equal false, trace.inserted
    assert_equal File.new(fixture).read, File.new(trace.trace_name).read
    trace.destroy
    assert_equal "trackable", user.preferences.where(:k => "gps.trace.visibility").first.v
  end

  # Test fetching the edit page for a trace using GET
  def test_edit_get
    public_trace_file = create(:trace, :visibility => "public")
    deleted_trace_file = create(:trace, :deleted)

    # First with no auth
    get :edit, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :referer => trace_edit_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file.id)

    # Now with some other user, which should fail
    get :edit, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }, :session => { :user => create(:user) }
    assert_response :forbidden

    # Now with a trace which doesn't exist
    get :edit, :params => { :display_name => create(:user).display_name, :id => 0 }, :session => { :user => create(:user) }
    assert_response :not_found

    # Now with a trace which has been deleted
    get :edit, :params => { :display_name => deleted_trace_file.user.display_name, :id => deleted_trace_file.id }, :session => { :user => deleted_trace_file.user }
    assert_response :not_found

    # Finally with a trace that we are allowed to edit
    get :edit, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }, :session => { :user => public_trace_file.user }
    assert_response :success
  end

  # Test fetching the edit page for a trace using POST
  def test_edit_post_no_details
    public_trace_file = create(:trace, :visibility => "public")
    deleted_trace_file = create(:trace, :deleted)

    # First with no auth
    post :edit, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }
    assert_response :forbidden

    # Now with some other user, which should fail
    post :edit, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }, :session => { :user => create(:user) }
    assert_response :forbidden

    # Now with a trace which doesn't exist
    post :edit, :params => { :display_name => create(:user).display_name, :id => 0 }, :session => { :user => create(:user) }
    assert_response :not_found

    # Now with a trace which has been deleted
    post :edit, :params => { :display_name => deleted_trace_file.user.display_name, :id => deleted_trace_file.id }, :session => { :user => deleted_trace_file.user }
    assert_response :not_found

    # Finally with a trace that we are allowed to edit
    post :edit, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }, :session => { :user => public_trace_file.user }
    assert_response :success
  end

  # Test saving edits to a trace
  def test_edit_post_with_details
    public_trace_file = create(:trace, :visibility => "public")
    deleted_trace_file = create(:trace, :deleted)

    # New details
    new_details = { :description => "Changed description", :tagstring => "new_tag", :visibility => "private" }

    # First with no auth
    post :edit, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id, :trace => new_details }
    assert_response :forbidden

    # Now with some other user, which should fail
    post :edit, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id, :trace => new_details }, :session => { :user => create(:user) }
    assert_response :forbidden

    # Now with a trace which doesn't exist
    post :edit, :params => { :display_name => create(:user).display_name, :id => 0 }, :session => { :user => create(:user), :trace => new_details }
    assert_response :not_found

    # Now with a trace which has been deleted
    post :edit, :params => { :display_name => deleted_trace_file.user.display_name, :id => deleted_trace_file.id, :trace => new_details }, :session => { :user => deleted_trace_file.user }
    assert_response :not_found

    # Finally with a trace that we are allowed to edit
    post :edit, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id, :trace => new_details }, :session => { :user => public_trace_file.user }
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => public_trace_file.user.display_name
    trace = Trace.find(public_trace_file.id)
    assert_equal new_details[:description], trace.description
    assert_equal new_details[:tagstring], trace.tagstring
    assert_equal new_details[:visibility], trace.visibility
  end

  # Test deleting a trace
  def test_delete
    public_trace_file = create(:trace, :visibility => "public")
    deleted_trace_file = create(:trace, :deleted)

    # First with no auth
    post :delete, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }
    assert_response :forbidden

    # Now with some other user, which should fail
    post :delete, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }, :session => { :user => create(:user) }
    assert_response :forbidden

    # Now with a trace which doesn't exist
    post :delete, :params => { :display_name => create(:user).display_name, :id => 0 }, :session => { :user => create(:user) }
    assert_response :not_found

    # Now with a trace has already been deleted
    post :delete, :params => { :display_name => deleted_trace_file.user.display_name, :id => deleted_trace_file.id }, :session => { :user => deleted_trace_file.user }
    assert_response :not_found

    # Now with a trace that we are allowed to delete
    post :delete, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }, :session => { :user => public_trace_file.user }
    assert_response :redirect
    assert_redirected_to :action => :list, :display_name => public_trace_file.user.display_name
    trace = Trace.find(public_trace_file.id)
    assert_equal false, trace.visible

    # Finally with a trace that is deleted by an admin
    public_trace_file = create(:trace, :visibility => "public")
    admin = create(:administrator_user)

    post :delete, :params => { :display_name => public_trace_file.user.display_name, :id => public_trace_file.id }, :session => { :user => admin }
    assert_response :redirect
    assert_redirected_to :action => :list, :display_name => public_trace_file.user.display_name
    trace = Trace.find(public_trace_file.id)
    assert_equal false, trace.visible
  end

  # Check getting a specific trace through the api
  def test_api_read
    public_trace_file = create(:trace, :visibility => "public")

    # First with no auth
    get :api_read, :params => { :id => public_trace_file.id }
    assert_response :unauthorized

    # Now with some other user, which should work since the trace is public
    basic_authorization create(:user).display_name, "test"
    get :api_read, :params => { :id => public_trace_file.id }
    assert_response :success

    # And finally we should be able to do it with the owner of the trace
    basic_authorization public_trace_file.user.display_name, "test"
    get :api_read, :params => { :id => public_trace_file.id }
    assert_response :success
  end

  # Check an anoymous trace can't be specifically fetched by another user
  def test_api_read_anon
    anon_trace_file = create(:trace, :visibility => "private")

    # First with no auth
    get :api_read, :params => { :id => anon_trace_file.id }
    assert_response :unauthorized

    # Now try with another user, which shouldn't work since the trace is anon
    basic_authorization create(:user).display_name, "test"
    get :api_read, :params => { :id => anon_trace_file.id }
    assert_response :forbidden

    # And finally we should be able to get the trace details with the trace owner
    basic_authorization anon_trace_file.user.display_name, "test"
    get :api_read, :params => { :id => anon_trace_file.id }
    assert_response :success
  end

  # Check the api details for a trace that doesn't exist
  def test_api_read_not_found
    deleted_trace_file = create(:trace, :deleted)

    # Try first with no auth, as it should require it
    get :api_read, :params => { :id => 0 }
    assert_response :unauthorized

    # Login, and try again
    basic_authorization deleted_trace_file.user.display_name, "test"
    get :api_read, :params => { :id => 0 }
    assert_response :not_found

    # Now try a trace which did exist but has been deleted
    basic_authorization deleted_trace_file.user.display_name, "test"
    get :api_read, :params => { :id => deleted_trace_file.id }
    assert_response :not_found
  end

  # Test downloading a trace through the api
  def test_api_data
    public_trace_file = create(:trace, :visibility => "public", :fixture => "a")

    # First with no auth
    get :api_data, :params => { :id => public_trace_file.id }
    assert_response :unauthorized

    # Now with some other user, which should work since the trace is public
    basic_authorization create(:user).display_name, "test"
    get :api_data, :params => { :id => public_trace_file.id }
    check_trace_data public_trace_file, "848caa72f2f456d1bd6a0fdf228aa1b9"

    # And finally we should be able to do it with the owner of the trace
    basic_authorization public_trace_file.user.display_name, "test"
    get :api_data, :params => { :id => public_trace_file.id }
    check_trace_data public_trace_file, "848caa72f2f456d1bd6a0fdf228aa1b9"
  end

  # Test downloading a compressed trace through the api
  def test_api_data_compressed
    identifiable_trace_file = create(:trace, :visibility => "identifiable", :fixture => "d")

    # Authenticate as the owner of the trace we will be using
    basic_authorization identifiable_trace_file.user.display_name, "test"

    # First get the data as is
    get :api_data, :params => { :id => identifiable_trace_file.id }
    check_trace_data identifiable_trace_file, "c6422a3d8750faae49ed70e7e8a51b93", "application/x-gzip", "gpx.gz"

    # Now ask explicitly for XML format
    get :api_data, :params => { :id => identifiable_trace_file.id, :format => "xml" }
    check_trace_data identifiable_trace_file, "abd6675fdf3024a84fc0a1deac147c0d", "application/xml", "xml"

    # Now ask explicitly for GPX format
    get :api_data, :params => { :id => identifiable_trace_file.id, :format => "gpx" }
    check_trace_data identifiable_trace_file, "abd6675fdf3024a84fc0a1deac147c0d"
  end

  # Check an anonymous trace can't be downloaded by another user through the api
  def test_api_data_anon
    anon_trace_file = create(:trace, :visibility => "private", :fixture => "b")

    # First with no auth
    get :api_data, :params => { :id => anon_trace_file.id }
    assert_response :unauthorized

    # Now with some other user, which shouldn't work since the trace is anon
    basic_authorization create(:user).display_name, "test"
    get :api_data, :params => { :id => anon_trace_file.id }
    assert_response :forbidden

    # And finally we should be able to do it with the owner of the trace
    basic_authorization anon_trace_file.user.display_name, "test"
    get :api_data, :params => { :id => anon_trace_file.id }
    check_trace_data anon_trace_file, "66179ca44f1e93d8df62e2b88cbea732"
  end

  # Test downloading a trace that doesn't exist through the api
  def test_api_data_not_found
    deleted_trace_file = create(:trace, :deleted)

    # Try first with no auth, as it should require it
    get :api_data, :params => { :id => 0 }
    assert_response :unauthorized

    # Login, and try again
    basic_authorization create(:user).display_name, "test"
    get :api_data, :params => { :id => 0 }
    assert_response :not_found

    # Now try a trace which did exist but has been deleted
    basic_authorization deleted_trace_file.user.display_name, "test"
    get :api_data, :params => { :id => deleted_trace_file.id }
    assert_response :not_found
  end

  # Test creating a trace through the api
  def test_api_create
    # Get file to use
    fixture = Rails.root.join("test", "gpx", "fixtures", "a.gpx")
    file = Rack::Test::UploadedFile.new(fixture, "application/gpx+xml")
    user = create(:user)

    # First with no auth
    post :api_create, :params => { :file => file, :description => "New Trace", :tags => "new,trace", :visibility => "trackable" }
    assert_response :unauthorized

    # Rewind the file
    file.rewind

    # Now authenticated
    create(:user_preference, :user => user, :k => "gps.trace.visibility", :v => "identifiable")
    assert_not_equal "trackable", user.preferences.where(:k => "gps.trace.visibility").first.v
    basic_authorization user.display_name, "test"
    post :api_create, :params => { :file => file, :description => "New Trace", :tags => "new,trace", :visibility => "trackable" }
    assert_response :success
    trace = Trace.find(response.body.to_i)
    assert_equal "a.gpx", trace.name
    assert_equal "New Trace", trace.description
    assert_equal %w[new trace], trace.tags.order(:tag).collect(&:tag)
    assert_equal "trackable", trace.visibility
    assert_equal false, trace.inserted
    assert_equal File.new(fixture).read, File.new(trace.trace_name).read
    trace.destroy
    assert_equal "trackable", user.preferences.where(:k => "gps.trace.visibility").first.v

    # Rewind the file
    file.rewind

    # Now authenticated, with the legacy public flag
    assert_not_equal "public", user.preferences.where(:k => "gps.trace.visibility").first.v
    basic_authorization user.display_name, "test"
    post :api_create, :params => { :file => file, :description => "New Trace", :tags => "new,trace", :public => 1 }
    assert_response :success
    trace = Trace.find(response.body.to_i)
    assert_equal "a.gpx", trace.name
    assert_equal "New Trace", trace.description
    assert_equal %w[new trace], trace.tags.order(:tag).collect(&:tag)
    assert_equal "public", trace.visibility
    assert_equal false, trace.inserted
    assert_equal File.new(fixture).read, File.new(trace.trace_name).read
    trace.destroy
    assert_equal "public", user.preferences.where(:k => "gps.trace.visibility").first.v

    # Rewind the file
    file.rewind

    # Now authenticated, with the legacy private flag
    second_user = create(:user)
    assert_nil second_user.preferences.where(:k => "gps.trace.visibility").first
    basic_authorization second_user.display_name, "test"
    post :api_create, :params => { :file => file, :description => "New Trace", :tags => "new,trace", :public => 0 }
    assert_response :success
    trace = Trace.find(response.body.to_i)
    assert_equal "a.gpx", trace.name
    assert_equal "New Trace", trace.description
    assert_equal %w[new trace], trace.tags.order(:tag).collect(&:tag)
    assert_equal "private", trace.visibility
    assert_equal false, trace.inserted
    assert_equal File.new(fixture).read, File.new(trace.trace_name).read
    trace.destroy
    assert_equal "private", second_user.preferences.where(:k => "gps.trace.visibility").first.v
  end

  # Check updating a trace through the api
  def test_api_update
    public_trace_file = create(:trace, :visibility => "public", :fixture => "a")
    deleted_trace_file = create(:trace, :deleted)
    anon_trace_file = create(:trace, :visibility => "private")

    # First with no auth
    content public_trace_file.to_xml
    put :api_update, :params => { :id => public_trace_file.id }
    assert_response :unauthorized

    # Now with some other user, which should fail
    basic_authorization create(:user).display_name, "test"
    content public_trace_file.to_xml
    put :api_update, :params => { :id => public_trace_file.id }
    assert_response :forbidden

    # Now with a trace which doesn't exist
    basic_authorization create(:user).display_name, "test"
    content public_trace_file.to_xml
    put :api_update, :params => { :id => 0 }
    assert_response :not_found

    # Now with a trace which did exist but has been deleted
    basic_authorization deleted_trace_file.user.display_name, "test"
    content deleted_trace_file.to_xml
    put :api_update, :params => { :id => deleted_trace_file.id }
    assert_response :not_found

    # Now try an update with the wrong ID
    basic_authorization public_trace_file.user.display_name, "test"
    content anon_trace_file.to_xml
    put :api_update, :params => { :id => public_trace_file.id }
    assert_response :bad_request,
                    "should not be able to update a trace with a different ID from the XML"

    # And finally try an update that should work
    basic_authorization public_trace_file.user.display_name, "test"
    t = public_trace_file
    t.description = "Changed description"
    t.visibility = "private"
    content t.to_xml
    put :api_update, :params => { :id => t.id }
    assert_response :success
    nt = Trace.find(t.id)
    assert_equal nt.description, t.description
    assert_equal nt.visibility, t.visibility
  end

  # Test that updating a trace doesn't duplicate the tags
  def test_api_update_tags
    tracetag = create(:tracetag)
    trace = tracetag.trace
    basic_authorization trace.user.display_name, "test"

    content trace.to_xml
    put :api_update, :params => { :id => trace.id }
    assert_response :success

    updated = Trace.find(trace.id)
    # Ensure there's only one tag in the database after updating
    assert_equal Tracetag.count, 1
    # The new tag object might have a different id, so check the string representation
    assert_equal trace.tagstring, updated.tagstring
  end

  # Check deleting a trace through the api
  def test_api_delete
    public_trace_file = create(:trace, :visibility => "public")

    # First with no auth
    delete :api_delete, :params => { :id => public_trace_file.id }
    assert_response :unauthorized

    # Now with some other user, which should fail
    basic_authorization create(:user).display_name, "test"
    delete :api_delete, :params => { :id => public_trace_file.id }
    assert_response :forbidden

    # Now with a trace which doesn't exist
    basic_authorization create(:user).display_name, "test"
    delete :api_delete, :params => { :id => 0 }
    assert_response :not_found

    # And finally we should be able to do it with the owner of the trace
    basic_authorization public_trace_file.user.display_name, "test"
    delete :api_delete, :params => { :id => public_trace_file.id }
    assert_response :success

    # Try it a second time, which should fail
    basic_authorization public_trace_file.user.display_name, "test"
    delete :api_delete, :params => { :id => public_trace_file.id }
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

    if !traces.empty?
      assert_select "table#trace_list tbody", :count => 1 do
        assert_select "tr", :count => traces.length do |rows|
          traces.zip(rows).each do |trace, row|
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

  def check_trace_data(trace, digest, content_type = "application/gpx+xml", extension = "gpx")
    assert_response :success
    assert_equal digest, Digest::MD5.hexdigest(response.body)
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
