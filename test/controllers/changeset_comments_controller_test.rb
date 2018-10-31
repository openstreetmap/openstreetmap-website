require "test_helper"

class ChangesetCommentsControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/changeset/1/comment", :method => :post },
      { :controller => "changeset_comments", :action => "create", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/comment/1/hide", :method => :post },
      { :controller => "changeset_comments", :action => "hide_comment", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/comment/1/unhide", :method => :post },
      { :controller => "changeset_comments", :action => "unhide_comment", :id => "1" }
    )
    assert_routing(
      { :path => "/changeset/1/comments/feed", :method => :get },
      { :controller => "changeset_comments", :action => "comments_feed", :id => "1", :format => "rss" }
    )
    assert_routing(
      { :path => "/history/comments/feed", :method => :get },
      { :controller => "changeset_comments", :action => "comments_feed", :format => "rss" }
    )
  end

  ##
  # create comment success
  def test_create_comment_success
    user = create(:user)
    user2 = create(:user)
    private_user = create(:user, :data_public => false)
    suspended_user = create(:user, :suspended)
    deleted_user = create(:user, :deleted)
    private_user_closed_changeset = create(:changeset, :closed, :user => private_user)

    basic_authorization user.email, "test"

    assert_difference "ChangesetComment.count", 1 do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post :create, :params => { :id => private_user_closed_changeset.id, :text => "This is a comment" }
        end
      end
    end
    assert_response :success

    changeset = create(:changeset, :closed, :user => private_user)
    changeset.subscribers.push(private_user)
    changeset.subscribers.push(user)
    changeset.subscribers.push(suspended_user)
    changeset.subscribers.push(deleted_user)

    assert_difference "ChangesetComment.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        perform_enqueued_jobs do
          post :create, :params => { :id => changeset.id, :text => "This is a comment" }
        end
      end
    end
    assert_response :success

    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.to.length
    assert_equal "[OpenStreetMap] #{user.display_name} has commented on one of your changesets", email.subject
    assert_equal private_user.email, email.to.first

    ActionMailer::Base.deliveries.clear

    basic_authorization user2.email, "test"

    assert_difference "ChangesetComment.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 2 do
        perform_enqueued_jobs do
          post :create, :params => { :id => changeset.id, :text => "This is a comment" }
        end
      end
    end
    assert_response :success

    email = ActionMailer::Base.deliveries.find { |e| e.to.first == private_user.email }
    assert_not_nil email
    assert_equal 1, email.to.length
    assert_equal "[OpenStreetMap] #{user2.display_name} has commented on one of your changesets", email.subject

    email = ActionMailer::Base.deliveries.find { |e| e.to.first == user.email }
    assert_not_nil email
    assert_equal 1, email.to.length
    assert_equal "[OpenStreetMap] #{user2.display_name} has commented on a changeset you are interested in", email.subject

    ActionMailer::Base.deliveries.clear
  end

  ##
  # create comment fail
  def test_create_comment_fail
    # unauthorized
    post :create, :params => { :id => create(:changeset, :closed).id, :text => "This is a comment" }
    assert_response :unauthorized

    basic_authorization create(:user).email, "test"

    # bad changeset id
    assert_no_difference "ChangesetComment.count" do
      post :create, :params => { :id => 999111, :text => "This is a comment" }
    end
    assert_response :not_found

    # not closed changeset
    assert_no_difference "ChangesetComment.count" do
      post :create, :params => { :id => create(:changeset).id, :text => "This is a comment" }
    end
    assert_response :conflict

    # no text
    assert_no_difference "ChangesetComment.count" do
      post :create, :params => { :id => create(:changeset, :closed).id }
    end
    assert_response :bad_request

    # empty text
    assert_no_difference "ChangesetComment.count" do
      post :create, :params => { :id => create(:changeset, :closed).id, :text => "" }
    end
    assert_response :bad_request
  end

  ##
  # test hide comment fail
  def test_hide_comment_fail
    # unauthorized
    comment = create(:changeset_comment)
    assert_equal true, comment.visible

    post :hide_comment, :params => { :id => comment.id }
    assert_response :unauthorized
    assert_equal true, comment.reload.visible

    basic_authorization create(:user).email, "test"

    # not a moderator
    post :hide_comment, :params => { :id => comment.id }
    assert_response :forbidden
    assert_equal true, comment.reload.visible

    basic_authorization create(:moderator_user).email, "test"

    # bad comment id
    post :hide_comment, :params => { :id => 999111 }
    assert_response :not_found
    assert_equal true, comment.reload.visible
  end

  ##
  # test hide comment succes
  def test_hide_comment_success
    comment = create(:changeset_comment)
    assert_equal true, comment.visible

    basic_authorization create(:moderator_user).email, "test"

    post :hide_comment, :params => { :id => comment.id }
    assert_response :success
    assert_equal false, comment.reload.visible
  end

  ##
  # test unhide comment fail
  def test_unhide_comment_fail
    # unauthorized
    comment = create(:changeset_comment, :visible => false)
    assert_equal false, comment.visible

    post :unhide_comment, :params => { :id => comment.id }
    assert_response :unauthorized
    assert_equal false, comment.reload.visible

    basic_authorization create(:user).email, "test"

    # not a moderator
    post :unhide_comment, :params => { :id => comment.id }
    assert_response :forbidden
    assert_equal false, comment.reload.visible

    basic_authorization create(:moderator_user).email, "test"

    # bad comment id
    post :unhide_comment, :params => { :id => 999111 }
    assert_response :not_found
    assert_equal false, comment.reload.visible
  end

  ##
  # test unhide comment succes
  def test_unhide_comment_success
    comment = create(:changeset_comment, :visible => false)
    assert_equal false, comment.visible

    basic_authorization create(:moderator_user).email, "test"

    post :unhide_comment, :params => { :id => comment.id }
    assert_response :success
    assert_equal true, comment.reload.visible
  end

  ##
  # test comments feed
  def test_comments_feed
    changeset = create(:changeset, :closed)
    create_list(:changeset_comment, 3, :changeset => changeset)

    get :comments_feed, :params => { :format => "rss" }
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 3
      end
    end

    get :comments_feed, :params => { :format => "rss", :limit => 2 }
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 2
      end
    end

    get :comments_feed, :params => { :id => changeset.id, :format => "rss" }
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 3
      end
    end
  end

  ##
  # test comments feed
  def test_comments_feed_bad_limit
    get :comments_feed, :params => { :format => "rss", :limit => 0 }
    assert_response :bad_request

    get :comments_feed, :params => { :format => "rss", :limit => 100001 }
    assert_response :bad_request
  end
end
