require "test_helper"

class TracesControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/traces", :method => :get },
      { :controller => "traces", :action => "index" }
    )
    assert_routing(
      { :path => "/traces/page/1", :method => :get },
      { :controller => "traces", :action => "index", :page => "1" }
    )
    assert_routing(
      { :path => "/traces/tag/tagname", :method => :get },
      { :controller => "traces", :action => "index", :tag => "tagname" }
    )
    assert_routing(
      { :path => "/traces/tag/tagname/page/1", :method => :get },
      { :controller => "traces", :action => "index", :tag => "tagname", :page => "1" }
    )
    assert_routing(
      { :path => "/user/username/traces", :method => :get },
      { :controller => "traces", :action => "index", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/traces/page/1", :method => :get },
      { :controller => "traces", :action => "index", :display_name => "username", :page => "1" }
    )
    assert_routing(
      { :path => "/user/username/traces/tag/tagname", :method => :get },
      { :controller => "traces", :action => "index", :display_name => "username", :tag => "tagname" }
    )
    assert_routing(
      { :path => "/user/username/traces/tag/tagname/page/1", :method => :get },
      { :controller => "traces", :action => "index", :display_name => "username", :tag => "tagname", :page => "1" }
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
      { :controller => "traces", :action => "show", :display_name => "username", :id => "1" }
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
      { :path => "/traces/1/edit", :method => :get },
      { :controller => "traces", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/traces/1", :method => :put },
      { :controller => "traces", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/traces/1", :method => :delete },
      { :controller => "traces", :action => "destroy", :id => "1" }
    )
  end

  # Check that the index of traces is displayed
  def test_index
    user = create(:user)
    # The fourth test below is surprisingly sensitive to timestamp ordering when the timestamps are equal.
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

    # First with the public index
    get traces_path
    check_trace_index [trace_b, trace_a]

    # Restrict traces to those with a given tag
    get traces_path(:tag => "London")
    check_trace_index [trace_a]

    session_for(user)

    # Should see more when we are logged in
    get traces_path
    check_trace_index [trace_d, trace_c, trace_b, trace_a]

    # Again, we should see more when we are logged in
    get traces_path(:tag => "London")
    check_trace_index [trace_c, trace_a]
  end

  # Check that I can get mine
  def test_index_mine
    user = create(:user)
    create(:trace, :visibility => "public") do |trace|
      create(:tracetag, :trace => trace, :tag => "Birmingham")
    end
    trace_b = create(:trace, :visibility => "private", :user => user) do |trace|
      create(:tracetag, :trace => trace, :tag => "London")
    end

    # First try to get it when not logged in
    get traces_mine_path
    assert_redirected_to login_path(:referer => "/traces/mine")

    session_for(user)

    # Now try when logged in
    get traces_mine_path
    assert_redirected_to :action => "index", :display_name => user.display_name

    # Fetch the actual index
    get traces_path(:display_name => user.display_name)
    check_trace_index [trace_b]
  end

  # Check the index of traces for a specific user
  def test_index_user
    user = create(:user)
    second_user = create(:user)
    third_user = create(:user)
    create(:trace)
    trace_b = create(:trace, :visibility => "public", :user => user)
    trace_c = create(:trace, :visibility => "private", :user => user) do |trace|
      create(:tracetag, :trace => trace, :tag => "London")
    end

    # Test a user with no traces
    get traces_path(:display_name => second_user.display_name)
    check_trace_index []

    # Test the user with the traces - should see only public ones
    get traces_path(:display_name => user.display_name)
    check_trace_index [trace_b]

    session_for(third_user)

    # Should still see only public ones when authenticated as another user
    get traces_path(:display_name => user.display_name)
    check_trace_index [trace_b]

    session_for(user)

    # Should see all traces when authenticated as the target user
    get traces_path(:display_name => user.display_name)
    check_trace_index [trace_c, trace_b]

    # Should only see traces with the correct tag when a tag is specified
    get traces_path(:display_name => user.display_name, :tag => "London")
    check_trace_index [trace_c]

    # Should get an error if the user does not exist
    get traces_path(:display_name => "UnknownUser")
    assert_response :not_found
    assert_template "users/no_such_user"
  end

  # Check a multi-page index
  def test_index_paged
    # Create several pages worth of traces
    create_list(:trace, 50)

    # Try and get the index
    get traces_path
    assert_response :success
    assert_select "table#trace_list tbody", :count => 1 do
      assert_select "tr", :count => 20
    end

    # Try and get the second page
    get traces_path(:page => 2)
    assert_response :success
    assert_select "table#trace_list tbody", :count => 1 do
      assert_select "tr", :count => 20
    end
  end

  # Check the RSS feed
  def test_rss
    user = create(:user)
    # The fourth test below is surprisingly sensitive to timestamp ordering when the timestamps are equal.
    trace_a = create(:trace, :visibility => "public", :timestamp => 4.seconds.ago) do |trace|
      create(:tracetag, :trace => trace, :tag => "London")
    end
    trace_b = create(:trace, :visibility => "public", :timestamp => 3.seconds.ago) do |trace|
      create(:tracetag, :trace => trace, :tag => "Birmingham")
    end
    create(:trace, :visibility => "private", :user => user, :timestamp => 2.seconds.ago) do |trace|
      create(:tracetag, :trace => trace, :tag => "London")
    end
    create(:trace, :visibility => "private", :user => user, :timestamp => 1.second.ago) do |trace|
      create(:tracetag, :trace => trace, :tag => "Birmingham")
    end

    # First with the public feed
    get traces_rss_path
    check_trace_feed [trace_b, trace_a]

    # Restrict traces to those with a given tag
    get traces_rss_path(:tag => "London")
    check_trace_feed [trace_a]
  end

  # Check the RSS feed for a specific user
  def test_rss_user
    user = create(:user)
    second_user = create(:user)
    create(:user)
    create(:trace)
    trace_b = create(:trace, :visibility => "public", :timestamp => 4.seconds.ago, :user => user)
    trace_c = create(:trace, :visibility => "public", :timestamp => 3.seconds.ago, :user => user) do |trace|
      create(:tracetag, :trace => trace, :tag => "London")
    end
    create(:trace, :visibility => "private")

    # Test a user with no traces
    get traces_rss_path(:display_name => second_user.display_name)
    check_trace_feed []

    # Test the user with the traces - should see only public ones
    get traces_rss_path(:display_name => user.display_name)
    check_trace_feed [trace_c, trace_b]

    # Should only see traces with the correct tag when a tag is specified
    get traces_rss_path(:display_name => user.display_name, :tag => "London")
    check_trace_feed [trace_c]

    # Should no traces if the user does not exist
    get traces_rss_path(:display_name => "UnknownUser")
    check_trace_feed []
  end

  # Test showing a trace
  def test_show
    public_trace_file = create(:trace, :visibility => "public")

    # First with no auth, which should work since the trace is public
    get show_trace_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    check_trace_show public_trace_file

    # Now with some other user, which should work since the trace is public
    session_for(create(:user))
    get show_trace_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    check_trace_show public_trace_file

    # And finally we should be able to do it with the owner of the trace
    session_for(public_trace_file.user)
    get show_trace_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    check_trace_show public_trace_file
  end

  # Check an anonymous trace can't be viewed by another user
  def test_show_anon
    anon_trace_file = create(:trace, :visibility => "private")

    # First with no auth
    get show_trace_path(:display_name => anon_trace_file.user.display_name, :id => anon_trace_file)
    assert_response :redirect
    assert_redirected_to :action => :index

    # Now with some other user, which should not work since the trace is anon
    session_for(create(:user))
    get show_trace_path(:display_name => anon_trace_file.user.display_name, :id => anon_trace_file)
    assert_response :redirect
    assert_redirected_to :action => :index

    # And finally we should be able to do it with the owner of the trace
    session_for(anon_trace_file.user)
    get show_trace_path(:display_name => anon_trace_file.user.display_name, :id => anon_trace_file)
    check_trace_show anon_trace_file
  end

  # Test showing a trace that doesn't exist
  def test_show_not_found
    deleted_trace_file = create(:trace, :deleted)

    # First with a trace that has never existed
    get show_trace_path(:display_name => create(:user).display_name, :id => 0)
    assert_response :redirect
    assert_redirected_to :action => :index

    # Now with a trace that has been deleted
    session_for(deleted_trace_file.user)
    get show_trace_path(:display_name => deleted_trace_file.user.display_name, :id => deleted_trace_file)
    assert_response :redirect
    assert_redirected_to :action => :index
  end

  # Test downloading a trace
  def test_data
    public_trace_file = create(:trace, :visibility => "public", :fixture => "a")

    # First with no auth, which should work since the trace is public
    get trace_data_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    follow_redirect!
    follow_redirect!
    check_trace_data public_trace_file, "848caa72f2f456d1bd6a0fdf228aa1b9"

    # Now with some other user, which should work since the trace is public
    session_for(create(:user))
    get trace_data_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    follow_redirect!
    follow_redirect!
    check_trace_data public_trace_file, "848caa72f2f456d1bd6a0fdf228aa1b9"

    # And finally we should be able to do it with the owner of the trace
    session_for(public_trace_file.user)
    get trace_data_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    follow_redirect!
    follow_redirect!
    check_trace_data public_trace_file, "848caa72f2f456d1bd6a0fdf228aa1b9"
  end

  # Test downloading a compressed trace
  def test_data_compressed
    identifiable_trace_file = create(:trace, :visibility => "identifiable", :fixture => "d")

    # First get the data as is
    get trace_data_path(:display_name => identifiable_trace_file.user.display_name, :id => identifiable_trace_file)
    follow_redirect!
    follow_redirect!
    check_trace_data identifiable_trace_file, "c6422a3d8750faae49ed70e7e8a51b93", "application/gzip", "gpx.gz"

    # Now ask explicitly for XML format
    get trace_data_path(:display_name => identifiable_trace_file.user.display_name, :id => identifiable_trace_file.id, :format => "xml")
    check_trace_data identifiable_trace_file, "abd6675fdf3024a84fc0a1deac147c0d", "application/xml", "xml"

    # Now ask explicitly for GPX format
    get trace_data_path(:display_name => identifiable_trace_file.user.display_name, :id => identifiable_trace_file.id, :format => "gpx")
    check_trace_data identifiable_trace_file, "abd6675fdf3024a84fc0a1deac147c0d"
  end

  # Check an anonymous trace can't be downloaded by another user
  def test_data_anon
    anon_trace_file = create(:trace, :visibility => "private", :fixture => "b")

    # First with no auth
    get trace_data_path(:display_name => anon_trace_file.user.display_name, :id => anon_trace_file)
    assert_response :not_found

    # Now with some other user, which shouldn't work since the trace is anon
    session_for(create(:user))
    get trace_data_path(:display_name => anon_trace_file.user.display_name, :id => anon_trace_file)
    assert_response :not_found

    # And finally we should be able to do it with the owner of the trace
    session_for(anon_trace_file.user)
    get trace_data_path(:display_name => anon_trace_file.user.display_name, :id => anon_trace_file)
    follow_redirect!
    follow_redirect!
    check_trace_data anon_trace_file, "db4cb5ed2d7d2b627b3b504296c4f701"
  end

  # Test downloading a trace that doesn't exist
  def test_data_not_found
    deleted_trace_file = create(:trace, :deleted)

    # First with a trace that has never existed
    get trace_data_path(:display_name => create(:user).display_name, :id => 0)
    assert_response :not_found

    # Now with a trace that has been deleted
    session_for(deleted_trace_file.user)
    get trace_data_path(:display_name => deleted_trace_file.user.display_name, :id => deleted_trace_file)
    assert_response :not_found
  end

  # Test downloading the picture for a trace
  def test_picture
    public_trace_file = create(:trace, :visibility => "public", :fixture => "a")

    # First with no auth, which should work since the trace is public
    get trace_picture_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    check_trace_picture public_trace_file

    # Now with some other user, which should work since the trace is public
    session_for(create(:user))
    get trace_picture_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    check_trace_picture public_trace_file

    # And finally we should be able to do it with the owner of the trace
    session_for(public_trace_file.user)
    get trace_picture_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    check_trace_picture public_trace_file
  end

  # Check the picture for an anonymous trace can't be downloaded by another user
  def test_picture_anon
    anon_trace_file = create(:trace, :visibility => "private", :fixture => "b")

    # First with no auth
    get trace_picture_path(:display_name => anon_trace_file.user.display_name, :id => anon_trace_file)
    assert_response :forbidden

    # Now with some other user, which shouldn't work since the trace is anon
    session_for(create(:user))
    get trace_picture_path(:display_name => anon_trace_file.user.display_name, :id => anon_trace_file)
    assert_response :forbidden

    # And finally we should be able to do it with the owner of the trace
    session_for(anon_trace_file.user)
    get trace_picture_path(:display_name => anon_trace_file.user.display_name, :id => anon_trace_file)
    check_trace_picture anon_trace_file
  end

  # Test downloading the picture for a trace that doesn't exist
  def test_picture_not_found
    deleted_trace_file = create(:trace, :deleted)

    # First with a trace that has never existed
    get trace_picture_path(:display_name => create(:user).display_name, :id => 0)
    assert_response :not_found

    # Now with a trace that has been deleted
    session_for(deleted_trace_file.user)
    get trace_picture_path(:display_name => deleted_trace_file.user.display_name, :id => deleted_trace_file)
    assert_response :not_found
  end

  # Test downloading the icon for a trace
  def test_icon
    public_trace_file = create(:trace, :visibility => "public", :fixture => "a")

    # First with no auth, which should work since the trace is public
    get trace_icon_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    check_trace_icon public_trace_file

    # Now with some other user, which should work since the trace is public
    session_for(create(:user))
    get trace_icon_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    check_trace_icon public_trace_file

    # And finally we should be able to do it with the owner of the trace
    session_for(public_trace_file.user)
    get trace_icon_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    check_trace_icon public_trace_file
  end

  # Check the icon for an anonymous trace can't be downloaded by another user
  def test_icon_anon
    anon_trace_file = create(:trace, :visibility => "private", :fixture => "b")

    # First with no auth
    get trace_icon_path(:display_name => anon_trace_file.user.display_name, :id => anon_trace_file)
    assert_response :forbidden

    # Now with some other user, which shouldn't work since the trace is anon
    session_for(create(:user))
    get trace_icon_path(:display_name => anon_trace_file.user.display_name, :id => anon_trace_file)
    assert_response :forbidden

    # And finally we should be able to do it with the owner of the trace
    session_for(anon_trace_file.user)
    get trace_icon_path(:display_name => anon_trace_file.user.display_name, :id => anon_trace_file)
    check_trace_icon anon_trace_file
  end

  # Test downloading the icon for a trace that doesn't exist
  def test_icon_not_found
    deleted_trace_file = create(:trace, :deleted)

    # First with a trace that has never existed
    get trace_icon_path(:display_name => create(:user).display_name, :id => 0)
    assert_response :not_found

    # Now with a trace that has been deleted
    session_for(deleted_trace_file.user)
    get trace_icon_path(:display_name => deleted_trace_file.user.display_name, :id => deleted_trace_file)
    assert_response :not_found
  end

  # Test fetching the new trace page
  def test_new_get
    # First with no auth
    get new_trace_path
    assert_response :redirect
    assert_redirected_to login_path(:referer => new_trace_path)

    # Now authenticated as a user with gps.trace.visibility set
    user = create(:user)
    create(:user_preference, :user => user, :k => "gps.trace.visibility", :v => "identifiable")
    session_for(user)
    get new_trace_path
    assert_response :success
    assert_template :new
    assert_select "select#trace_visibility option[value=identifiable][selected]", 1

    # Now authenticated as a user with gps.trace.public set
    second_user = create(:user)
    create(:user_preference, :user => second_user, :k => "gps.trace.public", :v => "default")
    session_for(second_user)
    get new_trace_path
    assert_response :success
    assert_template :new
    assert_select "select#trace_visibility option[value=public][selected]", 1

    # Now authenticated as a user with no preferences
    third_user = create(:user)
    session_for(third_user)
    get new_trace_path
    assert_response :success
    assert_template :new
    assert_select "select#trace_visibility option[value=private][selected]", 1
  end

  # Test creating a trace
  def test_create_post
    # Get file to use
    fixture = Rails.root.join("test/gpx/fixtures/a.gpx")
    file = Rack::Test::UploadedFile.new(fixture, "application/gpx+xml")
    user = create(:user)

    # First with no auth
    post traces_path(:trace => { :gpx_file => file, :description => "New Trace", :tagstring => "new,trace", :visibility => "trackable" })
    assert_response :forbidden

    # Rewind the file
    file.rewind

    # Now authenticated
    create(:user_preference, :user => user, :k => "gps.trace.visibility", :v => "identifiable")
    assert_not_equal "trackable", user.preferences.where(:k => "gps.trace.visibility").first.v
    session_for(user)
    post traces_path, :params => { :trace => { :gpx_file => file, :description => "New Trace", :tagstring => "new,trace", :visibility => "trackable" } }
    assert_response :redirect
    assert_redirected_to :action => :index, :display_name => user.display_name
    assert_match(/file has been uploaded/, flash[:notice])
    trace = Trace.order(:id => :desc).first
    assert_equal "a.gpx", trace.name
    assert_equal "New Trace", trace.description
    assert_equal %w[new trace], trace.tags.order(:tag).collect(&:tag)
    assert_equal "trackable", trace.visibility
    assert_not trace.inserted
    assert_equal File.new(fixture).read, trace.file.blob.download
    trace.destroy
    assert_equal "trackable", user.preferences.where(:k => "gps.trace.visibility").first.v
  end

  # Test creating a trace with validation errors
  def test_create_post_with_validation_errors
    # Get file to use
    fixture = Rails.root.join("test/gpx/fixtures/a.gpx")
    file = Rack::Test::UploadedFile.new(fixture, "application/gpx+xml")
    user = create(:user)

    # Now authenticated
    create(:user_preference, :user => user, :k => "gps.trace.visibility", :v => "identifiable")
    assert_not_equal "trackable", user.preferences.where(:k => "gps.trace.visibility").first.v
    session_for(user)
    post traces_path, :params => { :trace => { :gpx_file => file, :description => "", :tagstring => "new,trace", :visibility => "trackable" } }
    assert_template :new
    assert_match "is too short (minimum is 1 character)", response.body
  end

  # Test fetching the edit page for a trace using GET
  def test_edit_get
    public_trace_file = create(:trace, :visibility => "public")
    deleted_trace_file = create(:trace, :deleted)

    # First with no auth
    get edit_trace_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    assert_response :redirect
    assert_redirected_to login_path(:referer => edit_trace_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file.id))

    # Now with some other user, which should fail
    session_for(create(:user))
    get edit_trace_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    assert_response :forbidden

    # Now with a trace which doesn't exist
    session_for(create(:user))
    get edit_trace_path(:display_name => create(:user).display_name, :id => 0)
    assert_response :not_found

    # Now with a trace which has been deleted
    session_for(deleted_trace_file.user)
    get edit_trace_path(:display_name => deleted_trace_file.user.display_name, :id => deleted_trace_file)
    assert_response :not_found

    # Finally with a trace that we are allowed to edit
    session_for(public_trace_file.user)
    get edit_trace_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    assert_response :success
  end

  # Test saving edits to a trace
  def test_update
    public_trace_file = create(:trace, :visibility => "public")
    deleted_trace_file = create(:trace, :deleted)

    # New details
    new_details = { :description => "Changed description", :tagstring => "new_tag", :visibility => "private" }

    # First with no auth
    put trace_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file, :trace => new_details)
    assert_response :forbidden

    # Now with some other user, which should fail
    session_for(create(:user))
    put trace_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file, :trace => new_details)
    assert_response :forbidden

    # Now with a trace which doesn't exist
    session_for(create(:user))
    put trace_path(:display_name => create(:user).display_name, :id => 0, :trace => new_details)
    assert_response :not_found

    # Now with a trace which has been deleted
    session_for(deleted_trace_file.user)
    put trace_path(:display_name => deleted_trace_file.user.display_name, :id => deleted_trace_file, :trace => new_details)
    assert_response :not_found

    # Finally with a trace that we are allowed to edit
    session_for(public_trace_file.user)
    put trace_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file, :trace => new_details)
    assert_response :redirect
    assert_redirected_to :action => :show, :display_name => public_trace_file.user.display_name
    trace = Trace.find(public_trace_file.id)
    assert_equal new_details[:description], trace.description
    assert_equal new_details[:tagstring], trace.tagstring
    assert_equal new_details[:visibility], trace.visibility
  end

  # Test destroying a trace
  def test_destroy
    public_trace_file = create(:trace, :visibility => "public")
    deleted_trace_file = create(:trace, :deleted)

    # First with no auth
    delete trace_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    assert_response :forbidden

    # Now with some other user, which should fail
    session_for(create(:user))
    delete trace_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    assert_response :forbidden

    # Now with a trace which doesn't exist
    session_for(create(:user))
    delete trace_path(:display_name => create(:user).display_name, :id => 0)
    assert_response :not_found

    # Now with a trace has already been deleted
    session_for(deleted_trace_file.user)
    delete trace_path(:display_name => deleted_trace_file.user.display_name, :id => deleted_trace_file)
    assert_response :not_found

    # Now with a trace that we are allowed to delete
    session_for(public_trace_file.user)
    delete trace_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    assert_response :redirect
    assert_redirected_to :action => :index, :display_name => public_trace_file.user.display_name
    trace = Trace.find(public_trace_file.id)
    assert_not trace.visible

    # Finally with a trace that is destroyed by an admin
    public_trace_file = create(:trace, :visibility => "public")
    admin = create(:administrator_user)
    session_for(admin)
    delete trace_path(:display_name => public_trace_file.user.display_name, :id => public_trace_file)
    assert_response :redirect
    assert_redirected_to :action => :index, :display_name => public_trace_file.user.display_name
    trace = Trace.find(public_trace_file.id)
    assert_not trace.visible
  end

  private

  def check_trace_feed(traces)
    assert_response :success
    assert_template "georss"
    assert_equal "application/rss+xml", @response.media_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "title"
        assert_select "description"
        assert_select "link"
        assert_select "image"
        assert_select "item", :count => traces.length do |items|
          traces.zip(items).each do |trace, item|
            assert_select item, "title", trace.name
            assert_select item, "link", "http://www.example.com/user/#{ERB::Util.u(trace.user.display_name)}/traces/#{trace.id}"
            assert_select item, "guid", "http://www.example.com/user/#{ERB::Util.u(trace.user.display_name)}/traces/#{trace.id}"
            assert_select item, "description"
            # assert_select item, "dc:creator", trace.user.display_name
            assert_select item, "pubDate", trace.timestamp.rfc822
          end
        end
      end
    end
  end

  def check_trace_index(traces)
    assert_response :success
    assert_template "index"

    if traces.empty?
      assert_select "h4", /Nothing here yet/
    else
      assert_select "table#trace_list tbody", :count => 1 do
        assert_select "tr", :count => traces.length do |rows|
          traces.zip(rows).each do |trace, row|
            assert_select row, "a", Regexp.new(Regexp.escape(trace.name))
            assert_select row, "li", Regexp.new(Regexp.escape("#{trace.size} points")) if trace.inserted?
            assert_select row, "td", Regexp.new(Regexp.escape(trace.description))
            assert_select row, "td", Regexp.new(Regexp.escape("by #{trace.user.display_name}"))
          end
        end
      end
    end
  end

  def check_trace_show(trace)
    assert_response :success
    assert_template "show"

    assert_select "table", :count => 1 do
      assert_select "td", /^#{Regexp.quote(trace.name)} /
      assert_select "td", trace.user.display_name
      assert_select "td", trace.description
    end
  end

  def check_trace_data(trace, digest, content_type = "application/gpx+xml", extension = "gpx")
    assert_equal digest, Digest::MD5.hexdigest(response.body)
    assert_equal content_type, response.media_type
    assert_equal "attachment; filename=\"#{trace.id}.#{extension}\"; filename*=UTF-8''#{trace.id}.#{extension}", @response.header["Content-Disposition"]
  end

  def check_trace_picture(trace)
    follow_redirect!
    follow_redirect!
    assert_response :success
    assert_equal "image/gif", response.media_type
    assert_equal trace.large_picture, response.body
  end

  def check_trace_icon(trace)
    follow_redirect!
    follow_redirect!
    assert_response :success
    assert_equal "image/gif", response.media_type
    assert_equal trace.icon_picture, response.body
  end
end
