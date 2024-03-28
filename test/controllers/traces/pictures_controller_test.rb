require "test_helper"

module Traces
  class PicturesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/user/username/traces/1/picture", :method => :get },
        { :controller => "traces/pictures", :action => "show", :display_name => "username", :trace_id => "1" }
      )
    end

    # Test downloading the picture for a trace
    def test_show
      public_trace_file = create(:trace, :visibility => "public", :fixture => "a")

      # First with no auth, which should work since the trace is public
      get trace_picture_path(public_trace_file.user, public_trace_file)
      check_trace_picture public_trace_file

      # Now with some other user, which should work since the trace is public
      session_for(create(:user))
      get trace_picture_path(public_trace_file.user, public_trace_file)
      check_trace_picture public_trace_file

      # And finally we should be able to do it with the owner of the trace
      session_for(public_trace_file.user)
      get trace_picture_path(public_trace_file.user, public_trace_file)
      check_trace_picture public_trace_file
    end

    # Check the picture for an anonymous trace can't be downloaded by another user
    def test_show_anon
      anon_trace_file = create(:trace, :visibility => "private", :fixture => "b")

      # First with no auth
      get trace_picture_path(anon_trace_file.user, anon_trace_file)
      assert_response :forbidden

      # Now with some other user, which shouldn't work since the trace is anon
      session_for(create(:user))
      get trace_picture_path(anon_trace_file.user, anon_trace_file)
      assert_response :forbidden

      # And finally we should be able to do it with the owner of the trace
      session_for(anon_trace_file.user)
      get trace_picture_path(anon_trace_file.user, anon_trace_file)
      check_trace_picture anon_trace_file
    end

    # Test downloading the picture for a trace that doesn't exist
    def test_show_not_found
      deleted_trace_file = create(:trace, :deleted)

      # First with a trace that has never existed
      get trace_picture_path(create(:user), 0)
      assert_response :not_found

      # Now with a trace that has been deleted
      session_for(deleted_trace_file.user)
      get trace_picture_path(deleted_trace_file.user, deleted_trace_file)
      assert_response :not_found
    end

    private

    def check_trace_picture(trace)
      follow_redirect!
      follow_redirect!
      assert_response :success
      assert_equal "image/gif", response.media_type
      assert_equal trace.large_picture, response.body
    end
  end
end
