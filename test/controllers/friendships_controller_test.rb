require "test_helper"

class FriendshipsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/username/follow_user", :method => :get },
      { :controller => "friendships", :action => "follow_user", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/follow_user", :method => :post },
      { :controller => "friendships", :action => "follow_user", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/unfollow_user", :method => :get },
      { :controller => "friendships", :action => "unfollow_user", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/unfollow_user", :method => :post },
      { :controller => "friendships", :action => "unfollow_user", :display_name => "username" }
    )
  end

  def test_follow_user
    # Get users to work with
    user = create(:user)
    friend = create(:user)

    # Check that the users aren't already friends
    assert_nil Friendship.find_by(:befriender => user, :befriendee => friend)

    # When not logged in a GET should ask us to login
    get follow_user_path(friend)
    assert_redirected_to login_path(:referer => follow_user_path(friend))

    # When not logged in a POST should error
    post follow_user_path(friend)
    assert_response :forbidden
    assert_nil Friendship.find_by(:befriender => user, :befriendee => friend)

    session_for(user)

    # When logged in a GET should get a confirmation page
    get follow_user_path(friend)
    assert_response :success
    assert_template :follow_user
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer']", 0
      assert_select "input[type='submit']", 1
    end
    assert_nil Friendship.find_by(:befriender => user, :befriendee => friend)

    # When logged in a POST should add the friendship
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post follow_user_path(friend)
      end
    end
    assert_redirected_to user_path(friend)
    assert_match(/You are now following/, flash[:notice])
    assert Friendship.find_by(:befriender => user, :befriendee => friend)
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal friend.email, email.to.first
    ActionMailer::Base.deliveries.clear

    # A second POST should report that the friendship already exists
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        post follow_user_path(friend)
      end
    end
    assert_redirected_to user_path(friend)
    assert_match(/You already follow/, flash[:warning])
    assert Friendship.find_by(:befriender => user, :befriendee => friend)
  end

  def test_follow_user_with_referer
    # Get users to work with
    user = create(:user)
    friend = create(:user)
    session_for(user)

    # Check that the users aren't already friends
    assert_nil Friendship.find_by(:befriender => user, :befriendee => friend)

    # The GET should preserve any referer
    get follow_user_path(friend), :params => { :referer => "/test" }
    assert_response :success
    assert_template :follow_user
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer'][value='/test']", 1
      assert_select "input[type='submit']", 1
    end
    assert_nil Friendship.find_by(:befriender => user, :befriendee => friend)

    # When logged in a POST should add the friendship and refer us
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post follow_user_path(friend), :params => { :referer => "/test" }
      end
    end
    assert_redirected_to "/test"
    assert_match(/You are now following/, flash[:notice])
    assert Friendship.find_by(:befriender => user, :befriendee => friend)
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal friend.email, email.to.first
    ActionMailer::Base.deliveries.clear
  end

  def test_follow_user_unknown_user
    # Should error when a bogus user is specified
    session_for(create(:user))
    get follow_user_path("No Such User")
    assert_response :not_found
    assert_template :no_such_user
  end

  def test_unfollow
    # Get users to work with
    user = create(:user)
    friend = create(:user)
    create(:friendship, :befriender => user, :befriendee => friend)

    # Check that the users are friends
    assert Friendship.find_by(:befriender => user, :befriendee => friend)

    # When not logged in a GET should ask us to login
    get unfollow_user_path(friend)
    assert_redirected_to login_path(:referer => unfollow_user_path(friend))

    # When not logged in a POST should error
    post unfollow_user_path, :params => { :display_name => friend.display_name }
    assert_response :forbidden
    assert Friendship.find_by(:befriender => user, :befriendee => friend)

    session_for(user)

    # When logged in a GET should get a confirmation page
    get unfollow_user_path(friend)
    assert_response :success
    assert_template :unfollow_user
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer']", 0
      assert_select "input[type='submit']", 1
    end
    assert Friendship.find_by(:befriender => user, :befriendee => friend)

    # When logged in a POST should remove the friendship
    post unfollow_user_path(friend)
    assert_redirected_to user_path(friend)
    assert_match(/was unfollowed by you/, flash[:notice])
    assert_nil Friendship.find_by(:befriender => user, :befriendee => friend)

    # A second POST should report that the friendship does not exist
    post unfollow_user_path(friend)
    assert_redirected_to user_path(friend)
    assert_match(/is not followed by you/, flash[:error])
    assert_nil Friendship.find_by(:befriender => user, :befriendee => friend)
  end

  def test_unfollow_user_with_referer
    # Get users to work with
    user = create(:user)
    friend = create(:user)
    create(:friendship, :befriender => user, :befriendee => friend)
    session_for(user)

    # Check that the users are friends
    assert Friendship.find_by(:befriender => user, :befriendee => friend)

    # The GET should preserve any referer
    get unfollow_user_path(friend), :params => { :referer => "/test" }
    assert_response :success
    assert_template :unfollow_user
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer'][value='/test']", 1
      assert_select "input[type='submit']", 1
    end
    assert Friendship.find_by(:befriender => user, :befriendee => friend)

    # When logged in a POST should remove the friendship and refer
    post unfollow_user_path(friend), :params => { :referer => "/test" }
    assert_redirected_to "/test"
    assert_match(/was unfollowed by you/, flash[:notice])
    assert_nil Friendship.find_by(:befriender => user, :befriendee => friend)
  end

  def test_unfollow_user_unknown_user
    # Should error when a bogus user is specified
    session_for(create(:user))
    get unfollow_user_path("No Such User")
    assert_response :not_found
    assert_template :no_such_user
  end
end
