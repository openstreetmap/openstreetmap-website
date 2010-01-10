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
  def test_api_details
    # First with no auth
    get :api_details, :id => gpx_files(:public_trace_file).id
    assert_response :unauthorized

    # Now with some other user, which should work since the trace is public
    basic_authorization(users(:public_user).display_name, "test")
    get :api_details, :id => gpx_files(:public_trace_file).id
    assert_response :success

    # And finally we should be able to do it with the owner of the trace
    basic_authorization(users(:normal_user).display_name, "test")
    get :api_details, :id => gpx_files(:public_trace_file).id
    assert_response :success
  end

  # Check an anoymous trace can't be specifically fetched by another user
  def test_api_details_anon
    # Furst with no auth
    get :api_details, :id => gpx_files(:anon_trace_file).id
    assert_response :unauthorized

    # Now try with another user, which shouldn't work since the trace is anon
    basic_authorization(users(:normal_user).display_name, "test")
    get :api_details, :id => gpx_files(:anon_trace_file).id
    assert_response :forbidden

    # And finally we should be able to get the trace details with the trace owner
    basic_authorization(users(:public_user).display_name, "test")
    get :api_details, :id => gpx_files(:anon_trace_file).id
    assert_response :success
  end

  # Check the api details for a trace that doesn't exist
  def test_api_details_not_found
    # Try first with no auth, as it should requure it
    get :api_details, :id => 0
    assert_response :unauthorized

    # Login, and try again
    basic_authorization(users(:public_user).display_name, "test")
    get :api_details, :id => 0
    assert_response :not_found
  end
end
