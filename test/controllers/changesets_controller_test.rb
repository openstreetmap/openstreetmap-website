require "test_helper"

class ChangesetsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/name/history", :method => :get },
      { :controller => "changesets", :action => "index", :display_name => "name" }
    )
    assert_routing(
      { :path => "/user/name/history/feed", :method => :get },
      { :controller => "changesets", :action => "feed", :display_name => "name", :format => :atom }
    )
    assert_routing(
      { :path => "/history/friends", :method => :get },
      { :controller => "changesets", :action => "index", :friends => true, :format => :html }
    )
    assert_routing(
      { :path => "/history/nearby", :method => :get },
      { :controller => "changesets", :action => "index", :nearby => true, :format => :html }
    )
    assert_routing(
      { :path => "/history", :method => :get },
      { :controller => "changesets", :action => "index" }
    )
    assert_routing(
      { :path => "/history/feed", :method => :get },
      { :controller => "changesets", :action => "feed", :format => :atom }
    )
  end

  ##
  # This should display the last 20 changesets closed
  def test_index
    changesets = create_list(:changeset, 30, :num_changes => 1)

    get history_path(:format => "html")
    assert_response :success
    assert_template "history"
    assert_template :layout => "map"
    assert_select "h2", :text => "Changesets", :count => 1

    get history_path(:format => "html", :list => "1"), :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(changesets.last(20))
  end

  ##
  # This should display the last 20 changesets closed
  def test_index_xhr
    changesets = create_list(:changeset, 30, :num_changes => 1)

    get history_path(:format => "html"), :xhr => true
    assert_response :success
    assert_template "history"
    assert_template :layout => "xhr"
    assert_select "h2", :text => "Changesets", :count => 1

    get history_path(:format => "html", :list => "1"), :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(changesets.last(20))
  end

  ##
  # This should display the last 20 changesets closed in a specific area
  def test_index_bbox
    changesets = create_list(:changeset, 10, :num_changes => 1, :min_lat => 50000000, :max_lat => 50000001, :min_lon => 50000000, :max_lon => 50000001)
    other_changesets = create_list(:changeset, 10, :num_changes => 1, :min_lat => 0, :max_lat => 1, :min_lon => 0, :max_lon => 1)

    # First check they all show up without a bbox parameter
    get history_path(:format => "html", :list => "1"), :xhr => true
    assert_response :success
    assert_template "index"
    check_index_result(changesets + other_changesets)

    # Then check with bbox parameter
    get history_path(:format => "html", :bbox => "4.5,4.5,5.5,5.5")
    assert_response :success
    assert_template "history"
    assert_template :layout => "map"
    assert_select "h2", :text => "Changesets", :count => 1

    get history_path(:format => "html", :bbox => "4.5,4.5,5.5,5.5", :list => "1"), :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(changesets)
  end

  ##
  # Checks the display of the user changesets listing
  def test_index_user
    user = create(:user)
    create(:changeset, :user => user)
    create(:changeset, :closed, :user => user)

    get history_path(:format => "html", :display_name => user.display_name)
    assert_response :success
    assert_template "history"

    get history_path(:format => "html", :display_name => user.display_name, :list => "1"), :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(user.changesets)
  end

  ##
  # Checks the display of the user changesets listing for a private user
  def test_index_private_user
    private_user = create(:user, :data_public => false)
    create(:changeset, :user => private_user)
    create(:changeset, :closed, :user => private_user)

    get history_path(:format => "html", :display_name => private_user.display_name)
    assert_response :success
    assert_template "history"

    get history_path(:format => "html", :display_name => private_user.display_name, :list => "1"), :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result([])
  end

  ##
  # Check the not found of the index user changesets
  def test_index_user_not_found
    get history_path(:format => "html", :display_name => "Some random user")
    assert_response :not_found
    assert_template "users/no_such_user"

    get history_path(:format => "html", :display_name => "Some random user", :list => "1"), :xhr => true
    assert_response :not_found
    assert_template "users/no_such_user"
  end

  ##
  # Checks the display of the friends changesets listing
  def test_index_friends
    private_user = create(:user, :data_public => true)
    friendship = create(:friendship, :befriender => private_user)
    changeset = create(:changeset, :user => friendship.befriendee, :num_changes => 1)
    _changeset2 = create(:changeset, :user => create(:user), :num_changes => 1)

    get friend_changesets_path
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :login, :referer => friend_changesets_path

    session_for(private_user)

    get friend_changesets_path
    assert_response :success
    assert_template "history"

    get friend_changesets_path(:list => "1"), :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result([changeset])
  end

  ##
  # Checks the display of the nearby user changesets listing
  def test_index_nearby
    private_user = create(:user, :data_public => false, :home_lat => 51.1, :home_lon => 1.0)
    user = create(:user, :home_lat => 51.0, :home_lon => 1.0)
    far_away_user = create(:user, :home_lat => 51.0, :home_lon => 130)
    changeset = create(:changeset, :user => user, :num_changes => 1)
    _changeset2 = create(:changeset, :user => far_away_user, :num_changes => 1)

    get nearby_changesets_path
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :login, :referer => nearby_changesets_path

    session_for(private_user)

    get nearby_changesets_path
    assert_response :success
    assert_template "history"

    get nearby_changesets_path(:list => "1"), :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result([changeset])
  end

  ##
  # Check that we can't request later pages of the changesets index
  def test_index_max_id
    changeset = create(:changeset, :num_changes => 1)
    _changeset2 = create(:changeset, :num_changes => 1)

    get history_path(:format => "html", :max_id => changeset.id), :xhr => true
    assert_response :success
    assert_template "history"
    assert_template :layout => "xhr"
    assert_select "h2", :text => "Changesets", :count => 1

    get history_path(:format => "html", :list => "1", :max_id => changeset.id), :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result([changeset])
  end

  ##
  # Check that a list with a next page link works
  def test_index_more
    create_list(:changeset, 50)

    get history_path(:format => "html")
    assert_response :success

    get history_path(:format => "html"), :xhr => true
    assert_response :success
  end

  ##
  # This should display the last 20 non-empty changesets
  def test_feed
    changeset = create(:changeset, :num_changes => 1)
    create(:changeset_tag, :changeset => changeset)
    create(:changeset_tag, :changeset => changeset, :k => "website", :v => "http://example.com/")
    closed_changeset = create(:changeset, :closed, :num_changes => 1)
    _empty_changeset = create(:changeset, :num_changes => 0)

    get history_feed_path(:format => :atom)
    assert_response :success
    assert_template "index"
    assert_equal "application/atom+xml", response.media_type

    check_feed_result([changeset, closed_changeset])
  end

  ##
  # This should display the last 20 changesets closed in a specific area
  def test_feed_bbox
    changeset = create(:changeset, :num_changes => 1, :min_lat => 5 * GeoRecord::SCALE, :min_lon => 5 * GeoRecord::SCALE, :max_lat => 5 * GeoRecord::SCALE, :max_lon => 5 * GeoRecord::SCALE)
    create(:changeset_tag, :changeset => changeset)
    create(:changeset_tag, :changeset => changeset, :k => "website", :v => "http://example.com/")
    closed_changeset = create(:changeset, :closed, :num_changes => 1, :min_lat => 5 * GeoRecord::SCALE, :min_lon => 5 * GeoRecord::SCALE, :max_lat => 5 * GeoRecord::SCALE, :max_lon => 5 * GeoRecord::SCALE)
    _elsewhere_changeset = create(:changeset, :num_changes => 1, :min_lat => -5 * GeoRecord::SCALE, :min_lon => -5 * GeoRecord::SCALE, :max_lat => -5 * GeoRecord::SCALE, :max_lon => -5 * GeoRecord::SCALE)
    _empty_changeset = create(:changeset, :num_changes => 0, :min_lat => -5 * GeoRecord::SCALE, :min_lon => -5 * GeoRecord::SCALE, :max_lat => -5 * GeoRecord::SCALE, :max_lon => -5 * GeoRecord::SCALE)

    get history_feed_path(:format => :atom, :bbox => "4.5,4.5,5.5,5.5")
    assert_response :success
    assert_template "index"
    assert_equal "application/atom+xml", response.media_type

    check_feed_result([changeset, closed_changeset])
  end

  ##
  # Checks the display of the user changesets feed
  def test_feed_user
    user = create(:user)
    changesets = create_list(:changeset, 3, :user => user, :num_changes => 4)
    create(:changeset_tag, :changeset => changesets[1])
    create(:changeset_tag, :changeset => changesets[1], :k => "website", :v => "http://example.com/")
    _other_changeset = create(:changeset)

    get history_feed_path(:format => :atom, :display_name => user.display_name)

    assert_response :success
    assert_template "index"
    assert_equal "application/atom+xml", response.media_type

    check_feed_result(changesets)
  end

  ##
  # Check the not found of the user changesets feed
  def test_feed_user_not_found
    get history_feed_path(:format => "atom", :display_name => "Some random user")
    assert_response :not_found
  end

  ##
  # Check that we can't request later pages of the changesets feed
  def test_feed_max_id
    get history_feed_path(:format => "atom", :max_id => 100)
    assert_response :redirect
    assert_redirected_to :action => :feed
  end

  private

  ##
  # check the result of a index
  def check_index_result(changesets)
    assert_select "ol.changesets", :count => [changesets.size, 1].min do
      assert_select "li", :count => changesets.size

      changesets.each do |changeset|
        assert_select "li#changeset_#{changeset.id}", :count => 1
      end
    end
  end

  ##
  # check the result of a feed
  def check_feed_result(changesets)
    assert changesets.size <= 20

    assert_select "feed", :count => [changesets.size, 1].min do
      assert_select "> title", :count => 1, :text => /^Changesets/
      assert_select "> entry", :count => changesets.size

      changesets.each do |changeset|
        assert_select "> entry > id", changeset_url(:id => changeset.id)
      end
    end
  end
end
