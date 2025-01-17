require "test_helper"

module Users
  class StatusesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/user/username/status", :method => :put },
        { :controller => "users/statuses", :action => "update", :user_display_name => "username" }
      )
    end

    def test_update
      user = create(:user)

      # Try without logging in
      put user_status_path(user, :event => "confirm")
      assert_response :forbidden

      # Now try as a normal user
      session_for(user)
      put user_status_path(user, :event => "confirm")
      assert_redirected_to :controller => "/errors", :action => :forbidden

      # Finally try as an administrator
      session_for(create(:administrator_user))
      put user_status_path(user, :event => "confirm")
      assert_redirected_to user_path(user)
      assert_equal "confirmed", User.find(user.id).status
    end

    def test_destroy
      user = create(:user, :home_lat => 12.1, :home_lon => 12.1, :description => "test")

      # Try without logging in
      put user_status_path(user, :event => "soft_destroy")
      assert_response :forbidden

      # Now try as a normal user
      session_for(user)
      put user_status_path(user, :event => "soft_destroy")
      assert_redirected_to :controller => "/errors", :action => :forbidden

      # Finally try as an administrator
      session_for(create(:administrator_user))
      put user_status_path(user, :event => "soft_destroy")
      assert_redirected_to user_path(user)

      # Check that the user was deleted properly
      user.reload
      assert_equal "user_#{user.id}", user.display_name
      assert_equal "", user.description
      assert_nil user.home_lat
      assert_nil user.home_lon
      assert_not user.avatar.attached?
      assert_not user.email_valid
      assert_nil user.new_email
      assert_nil user.auth_provider
      assert_nil user.auth_uid
      assert_equal "deleted", user.status
    end
  end
end
