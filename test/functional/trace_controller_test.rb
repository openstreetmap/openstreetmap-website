require File.dirname(__FILE__) + '/../test_helper'

class TraceControllerTest < ActionController::TestCase
  fixtures :users, :gpx_files
  set_fixture_class :gpx_files => 'Trace'

  # Check that the list of changesets is displayed
  def test_list
    get :list
    assert_response :success
    assert_template 'list'
  end

  # Check that I can get mine
  def test_list_mine
    # First try to get it when not logged in
    get :mine
    assert_redirected_to :controller => 'user', :action => 'login', :referer => '/traces/mine'

    # Now try when logged in
    get :mine, {}, {:user => users(:public_user).id}
    assert_redirected_to :controller => 'trace', :action => 'list', :display_name => users(:public_user).display_name
  end

  # Check that the rss loads
  def test_rss
    get :georss
    assert_rss_success

    get :georss, :display_name => users(:normal_user).display_name
    assert_rss_success
  end

  def assert_rss_success
    assert_response :success
    assert_template nil
    assert_equal "application/rss+xml", @response.content_type
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
end
