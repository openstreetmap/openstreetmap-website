require "test_helper"

class FollowsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/username/follow", :method => :get },
      { :controller => "follows", :action => "show", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/follow", :method => :post },
      { :controller => "follows", :action => "create", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/follow", :method => :delete },
      { :controller => "follows", :action => "destroy", :display_name => "username" }
    )
  end

  def test_follow
    # Get users to work with
    user = create(:user)
    follow = create(:user)

    # Check that the users aren't already friends
    assert_nil Follow.find_by(:follower => user, :following => follow)

    # When not logged in a GET should ask us to login
    get follow_path(follow)
    assert_redirected_to login_path(:referer => follow_path(follow))

    # When not logged in a POST should error
    post follow_path(follow)
    assert_response :forbidden
    assert_nil Follow.find_by(:follower => user, :following => follow)

    session_for(user)

    # When logged in a GET should get a confirmation page
    get follow_path(follow)
    assert_response :success
    assert_template :show
    assert_select "a[href*='test']", 0
    assert_nil Follow.find_by(:follower => user, :following => follow)

    # When logged in a POST should add the follow
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post follow_path(follow)
      end
    end
    assert_redirected_to user_path(follow)
    assert_match(/You are now following/, flash[:notice])
    assert Follow.find_by(:follower => user, :following => follow)
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal follow.email, email.to.first

    # A second POST should report that the follow already exists
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        post follow_path(follow)
      end
    end
    assert_redirected_to user_path(follow)
    assert_match(/You already follow/, flash[:warning])
    assert Follow.find_by(:follower => user, :following => follow)
  end

  def test_follow_with_referer
    # Get users to work with
    user = create(:user)
    follow = create(:user)
    session_for(user)

    # Check that the users aren't already friends
    assert_nil Follow.find_by(:follower => user, :following => follow)

    # The GET should preserve any referer
    get follow_path(follow), :params => { :referer => "/test" }
    assert_response :success
    assert_template :show
    assert_select "a[href*='test']"
    assert_nil Follow.find_by(:follower => user, :following => follow)

    # When logged in a POST should add the follow and refer us
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post follow_path(follow), :params => { :referer => "/test" }
      end
    end
    assert_redirected_to "/test"
    assert_match(/You are now following/, flash[:notice])
    assert Follow.find_by(:follower => user, :following => follow)
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal follow.email, email.to.first
  end

  def test_follow_unknown_user
    # Should error when a bogus user is specified
    session_for(create(:user))
    get follow_path("No Such User")
    assert_response :not_found
    assert_template :no_such_user
  end

  def test_unfollow
    # Get users to work with
    user = create(:user)
    follow = create(:user)
    create(:follow, :follower => user, :following => follow)

    # Check that the users are friends
    assert Follow.find_by(:follower => user, :following => follow)

    # When not logged in a GET should ask us to login
    get follow_path(follow)
    assert_redirected_to login_path(:referer => follow_path(follow))

    # When not logged in a POST should error
    delete follow_path, :params => { :display_name => follow.display_name }
    assert_response :forbidden
    assert Follow.find_by(:follower => user, :following => follow)

    session_for(user)

    # When logged in a GET should get a confirmation page
    get follow_path(follow)
    assert_response :success
    assert_template :show
    assert_select "a[href*='test']", 0
    assert Follow.find_by(:follower => user, :following => follow)

    # When logged in a DELETE should remove the follow
    delete follow_path(follow)
    assert_redirected_to user_path(follow)
    assert_match(/You successfully unfollowed/, flash[:notice])
    assert_nil Follow.find_by(:follower => user, :following => follow)

    # A second DELETE should report that the follow does not exist
    delete follow_path(follow)
    assert_redirected_to user_path(follow)
    assert_match(/You are not following/, flash[:error])
    assert_nil Follow.find_by(:follower => user, :following => follow)
  end

  def test_unfollow_with_referer
    # Get users to work with
    user = create(:user)
    follow = create(:user)
    create(:follow, :follower => user, :following => follow)
    session_for(user)

    # Check that the users are friends
    assert Follow.find_by(:follower => user, :following => follow)

    # The GET should preserve any referer
    get follow_path(follow), :params => { :referer => "/test" }
    assert_response :success
    assert_template :show
    assert_select "a[href*='test']"
    assert Follow.find_by(:follower => user, :following => follow)

    # When logged in a POST should remove the follow and refer
    delete follow_path(follow), :params => { :referer => "/test" }
    assert_redirected_to "/test"
    assert_match(/You successfully unfollowed/, flash[:notice])
    assert_nil Follow.find_by(:follower => user, :following => follow)
  end

  def test_unfollow_unknown_user
    # Should error when a bogus user is specified
    session_for(create(:user))
    get follow_path("No Such User")
    assert_response :not_found
    assert_template :no_such_user
  end
end
