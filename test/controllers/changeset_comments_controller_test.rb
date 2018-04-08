require "test_helper"

class ChangesetCommentsControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/changesets/comments", :method => :get },
      { :controller => "changeset_comments", :action => "all" }
    )
    assert_routing(
      { :path => "/changesets/comments/page/1", :method => :get },
      { :controller => "changeset_comments", :action => "all", :page => "1" }
    )
    assert_routing(
      { :path => "/user/username/changesets/comments", :method => :get },
      { :controller => "changeset_comments", :action => "user", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/changesets/comments/page/1", :method => :get },
      { :controller => "changeset_comments", :action => "user", :display_name => "username", :page => "1" }
    )
    assert_routing(
      { :path => "/user/username/changesets/comments/subscribed", :method => :get },
      { :controller => "changeset_comments", :action => "subscribed", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/changesets/comments/subscribed/page/1", :method => :get },
      { :controller => "changeset_comments", :action => "subscribed", :display_name => "username", :page => "1" }
    )
    assert_routing(
      { :path => "/user/username/changesets/comments/received", :method => :get },
      { :controller => "changeset_comments", :action => "received", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/changesets/comments/received/page/1", :method => :get },
      { :controller => "changeset_comments", :action => "received", :display_name => "username", :page => "1" }
    )
  end

  # Records should be displayed in created_at descending order
  def test_list_changeset_comments_sort_order
    10.times do |count|
      # Create records with created_at values alternately before and after the current time
      create(:changeset_comment, :visible, :created_at => Time.now + ((-1)**count * count.minutes))
    end

    get :all
    check_changeset_comments_list ChangesetComment.all
  end

  # Only visible records should be displayed
  def test_list_only_displays_visible_comments
    create(:changeset_comment, :visible)
    create(:changeset_comment, :hidden)

    get :all
    check_changeset_comments_list ChangesetComment.visible
  end

  # List all changeset comments on all changesets
  def test_all_changeset_comments
    create_test_data

    get :all
    assert_select "title", Regexp.new(I18n.t("changeset_comments.list.title.all"))
    check_changeset_comments_list ChangesetComment.all
  end

  # List changeset comments created by the specified user
  def test_list_user_with_changeset_comments
    create_test_data

    # When no relevant changeset comments exist
    get :user,
        :params => { :display_name => create(:user).display_name }
    check_changeset_comments_list

    # When relevant changeset comments exist
    get :user,
        :params => { :display_name => @target_user.display_name }
    assert_select "title", Regexp.new(I18n.t("changeset_comments.list.title.user", :user => @target_user.display_name))
    check_changeset_comments_list @target_user.changeset_comments
  end

  # Case: Changeset comments for all changesets created by the target user
  def test_list_received_changeset_comments
    create_test_data

    # When no relevant changeset comments exist
    get :received,
        :params => { :display_name => create(:user).display_name }
    check_changeset_comments_list

    # When relevant changeset comments exist
    get :received,
        :params => { :display_name => @target_user.display_name }
    assert_select "title", Regexp.new(I18n.t("changeset_comments.list.title.received", :user => @target_user.display_name))
    check_changeset_comments_list ChangesetComment.where(:changeset => @target_user.changesets)
  end

  # Case: Changeset comments for all changesets which the target user has subscribed to
  def test_list_subscribed_changeset_comments
    create_test_data

    # Not logged in
    get :subscribed,
        :params => { :display_name => @target_user.display_name }
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :referer => "/user/#{URI.encode(@target_user.display_name)}/changesets/comments/subscribed"

    # Logged in as another user
    another_user = create(:user)

    get :subscribed,
        :params => { :display_name => @target_user.display_name },
        :session => { :user => another_user }
    assert_response :redirect
    assert_redirected_to :controller => :changeset_comments, :action => :subscribed, :display_name => another_user.display_name

    # Logged in as target user but no relevant changeset comments exist
    user = create(:user)

    get :subscribed,
        :params => { :display_name => user.display_name },
        :session => { :user => user }
    check_changeset_comments_list

    # Logged in as target user and relevant changeset comments exist
    get :subscribed,
        :params => { :display_name => @target_user.display_name },
        :session => { :user => @target_user }
    assert_select "title", Regexp.new(I18n.t("changeset_comments.list.title.subscribed"))
    check_changeset_comments_list ChangesetComment.where(:changeset => @target_user.changeset_subscriptions)
  end

  private

  def create_test_data
    @target_user = create(:user)

    # Two changesets belonging to other users, each with three comments, two made by target_user
    create_list(:changeset, 2).each do |changeset|
      [@target_user, create(:user), @target_user].each do |user|
        create(:changeset_comment, :author => user, :changeset => changeset)
      end
    end

    # Two changesets belonging to target_user, each with three comments from other users
    create_list(:changeset_with_comments, 2, :comment_count => 3, :user => @target_user)

    # Two changesets belonging to other users, subscribed to by target_user and each with three comments
    create_list(:changeset_with_comments, 2, :comment_count => 3, :subscribers => [@target_user])
  end

  def check_changeset_comments_list(changeset_comments = [])
    assert_response :success
    assert_template "list"

    if changeset_comments.count.positive?
      assert_select "ul#changeset-comments", :count => 1 do
        assert_select "li", :count => changeset_comments.count do |list_items|
          changeset_comments.order("created_at DESC").zip(list_items).each do |changeset_comment, list_item|
            assert_select list_item, "h2", Regexp.new(I18n.t("changeset_comments.list.comment_heading_link_text", :id => changeset_comment.changeset.id))
            assert_select list_item, "p", Regexp.new(changeset_comment.body)
          end
        end
      end
    else
      assert_select "h2", I18n.t("changeset_comments.list.empty")
    end
  end
end
