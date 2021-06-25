require "test_helper"

class FriendshipsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/username/make_friend", :method => :get },
      { :controller => "friendships", :action => "make_friend", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/make_friend", :method => :post },
      { :controller => "friendships", :action => "make_friend", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/remove_friend", :method => :get },
      { :controller => "friendships", :action => "remove_friend", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/remove_friend", :method => :post },
      { :controller => "friendships", :action => "remove_friend", :display_name => "username" }
    )
  end

  def test_make_friend
    # Get users to work with
    user = create(:user)
    friend = create(:user)

    # Check that the users aren't already friends
    assert_nil Friendship.where(:befriender => user, :befriendee => friend).first

    # When not logged in a GET should ask us to login
    get make_friend_path(friend)
    assert_redirected_to login_path(:referer => make_friend_path(:display_name => friend.display_name))

    # When not logged in a POST should error
    post make_friend_path(friend)
    assert_response :forbidden
    assert_nil Friendship.where(:befriender => user, :befriendee => friend).first

    session_for(user)

    # When logged in a GET should get a confirmation page
    get make_friend_path(friend)
    assert_response :success
    assert_template :make_friend
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer']", 0
      assert_select "input[type='submit']", 1
    end
    assert_nil Friendship.where(:befriender => user, :befriendee => friend).first

    # When logged in a POST should add the friendship
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post make_friend_path(friend)
      end
    end
    assert_redirected_to user_path(friend)
    assert_match(/is now your friend/, flash[:notice])
    assert Friendship.where(:befriender => user, :befriendee => friend).first
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal friend.email, email.to.first
    ActionMailer::Base.deliveries.clear

    # A second POST should report that the friendship already exists
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      perform_enqueued_jobs do
        post make_friend_path(friend)
      end
    end
    assert_redirected_to user_path(friend)
    assert_match(/You are already friends with/, flash[:warning])
    assert Friendship.where(:befriender => user, :befriendee => friend).first
  end

  def test_make_friend_with_referer
    # Get users to work with
    user = create(:user)
    friend = create(:user)
    session_for(user)

    # Check that the users aren't already friends
    assert_nil Friendship.where(:befriender => user, :befriendee => friend).first

    # The GET should preserve any referer
    get make_friend_path(friend), :params => { :referer => "/test" }
    assert_response :success
    assert_template :make_friend
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer'][value='/test']", 1
      assert_select "input[type='submit']", 1
    end
    assert_nil Friendship.where(:befriender => user, :befriendee => friend).first

    # When logged in a POST should add the friendship and refer us
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      perform_enqueued_jobs do
        post make_friend_path(friend), :params => { :referer => "/test" }
      end
    end
    assert_redirected_to "/test"
    assert_match(/is now your friend/, flash[:notice])
    assert Friendship.where(:befriender => user, :befriendee => friend).first
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.count
    assert_equal friend.email, email.to.first
    ActionMailer::Base.deliveries.clear
  end

  def test_make_friend_unknown_user
    # Should error when a bogus user is specified
    session_for(create(:user))
    get make_friend_path(:display_name => "No Such User")
    assert_response :not_found
    assert_template :no_such_user
  end

  def test_remove_friend
    # Get users to work with
    user = create(:user)
    friend = create(:user)
    create(:friendship, :befriender => user, :befriendee => friend)

    # Check that the users are friends
    assert Friendship.where(:befriender => user, :befriendee => friend).first

    # When not logged in a GET should ask us to login
    get remove_friend_path(friend)
    assert_redirected_to login_path(:referer => remove_friend_path(:display_name => friend.display_name))

    # When not logged in a POST should error
    post remove_friend_path, :params => { :display_name => friend.display_name }
    assert_response :forbidden
    assert Friendship.where(:befriender => user, :befriendee => friend).first

    session_for(user)

    # When logged in a GET should get a confirmation page
    get remove_friend_path(friend)
    assert_response :success
    assert_template :remove_friend
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer']", 0
      assert_select "input[type='submit']", 1
    end
    assert Friendship.where(:befriender => user, :befriendee => friend).first

    # When logged in a POST should remove the friendship
    post remove_friend_path(friend)
    assert_redirected_to user_path(friend)
    assert_match(/was removed from your friends/, flash[:notice])
    assert_nil Friendship.where(:befriender => user, :befriendee => friend).first

    # A second POST should report that the friendship does not exist
    post remove_friend_path(friend)
    assert_redirected_to user_path(friend)
    assert_match(/is not one of your friends/, flash[:error])
    assert_nil Friendship.where(:befriender => user, :befriendee => friend).first
  end

  def test_remove_friend_with_referer
    # Get users to work with
    user = create(:user)
    friend = create(:user)
    create(:friendship, :befriender => user, :befriendee => friend)
    session_for(user)

    # Check that the users are friends
    assert Friendship.where(:befriender => user, :befriendee => friend).first

    # The GET should preserve any referer
    get remove_friend_path(friend), :params => { :referer => "/test" }
    assert_response :success
    assert_template :remove_friend
    assert_select "form" do
      assert_select "input[type='hidden'][name='referer'][value='/test']", 1
      assert_select "input[type='submit']", 1
    end
    assert Friendship.where(:befriender => user, :befriendee => friend).first

    # When logged in a POST should remove the friendship and refer
    post remove_friend_path(friend), :params => { :referer => "/test" }
    assert_redirected_to "/test"
    assert_match(/was removed from your friends/, flash[:notice])
    assert_nil Friendship.where(:befriender => user, :befriendee => friend).first
  end

  def test_remove_friend_unknown_user
    # Should error when a bogus user is specified
    session_for(create(:user))
    get remove_friend_path(:display_name => "No Such User")
    assert_response :not_found
    assert_template :no_such_user
  end
end
