require "test_helper"

class ChangesetsControllerTest < ActionController::TestCase
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
    get :index, :params => { :format => "html" }
    assert_response :success
    assert_template "history"
    assert_template :layout => "map"
    assert_select "h2", :text => "Changesets", :count => 1

    get :index, :params => { :format => "html", :list => "1" }, :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(Changeset.all)
  end

  ##
  # This should display the last 20 changesets closed
  def test_index_xhr
    get :index, :params => { :format => "html" }, :xhr => true
    assert_response :success
    assert_template "history"
    assert_template :layout => "xhr"
    assert_select "h2", :text => "Changesets", :count => 1

    get :index, :params => { :format => "html", :list => "1" }, :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(Changeset.all)
  end

  ##
  # This should display the last 20 changesets closed in a specific area
  def test_index_bbox
    get :index, :params => { :format => "html", :bbox => "4.5,4.5,5.5,5.5" }
    assert_response :success
    assert_template "history"
    assert_template :layout => "map"
    assert_select "h2", :text => "Changesets", :count => 1

    get :index, :params => { :format => "html", :bbox => "4.5,4.5,5.5,5.5", :list => "1" }, :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(Changeset.where("min_lon < 55000000 and max_lon > 45000000 and min_lat < 55000000 and max_lat > 45000000"))
  end

  ##
  # Checks the display of the user changesets listing
  def test_index_user
    user = create(:user)
    create(:changeset, :user => user)
    create(:changeset, :closed, :user => user)

    get :index, :params => { :format => "html", :display_name => user.display_name }
    assert_response :success
    assert_template "history"

    get :index, :params => { :format => "html", :display_name => user.display_name, :list => "1" }, :xhr => true
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

    get :index, :params => { :format => "html", :display_name => private_user.display_name }
    assert_response :success
    assert_template "history"

    get :index, :params => { :format => "html", :display_name => private_user.display_name, :list => "1" }, :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(Changeset.none)
  end

  ##
  # Check the not found of the index user changesets
  def test_index_user_not_found
    get :index, :params => { :format => "html", :display_name => "Some random user" }
    assert_response :not_found
    assert_template "users/no_such_user"

    get :index, :params => { :format => "html", :display_name => "Some random user", :list => "1" }, :xhr => true
    assert_response :not_found
    assert_template "users/no_such_user"
  end

  ##
  # Checks the display of the friends changesets listing
  def test_index_friends
    private_user = create(:user, :data_public => true)
    friendship = create(:friendship, :befriender => private_user)
    create(:changeset, :user => friendship.befriendee)

    get :index, :params => { :friends => true }
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :login, :referer => friend_changesets_path

    session[:user] = private_user.id

    get :index, :params => { :friends => true }
    assert_response :success
    assert_template "history"

    get :index, :params => { :friends => true, :list => "1" }, :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(Changeset.where(:user => private_user.friends.identifiable))
  end

  ##
  # Checks the display of the nearby user changesets listing
  def test_index_nearby
    private_user = create(:user, :data_public => false, :home_lat => 51.1, :home_lon => 1.0)
    user = create(:user, :home_lat => 51.0, :home_lon => 1.0)
    create(:changeset, :user => user)

    get :index, :params => { :nearby => true }
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :login, :referer => nearby_changesets_path

    session[:user] = private_user.id

    get :index, :params => { :nearby => true }
    assert_response :success
    assert_template "history"

    get :index, :params => { :nearby => true, :list => "1" }, :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(Changeset.where(:user => user.nearby))
  end

  ##
  # Check that we can't request later pages of the changesets index
  def test_index_max_id
    get :index, :params => { :format => "html", :max_id => 4 }, :xhr => true
    assert_response :success
    assert_template "history"
    assert_template :layout => "xhr"
    assert_select "h2", :text => "Changesets", :count => 1

    get :index, :params => { :format => "html", :list => "1", :max_id => 4 }, :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(Changeset.where("id <= 4"))
  end

  ##
  # Check that a list with a next page link works
  def test_index_more
    create_list(:changeset, 50)

    get :index, :params => { :format => "html" }
    assert_response :success

    get :index, :params => { :format => "html" }, :xhr => true
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

    get :feed, :params => { :format => :atom }
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

    get :feed, :params => { :format => :atom, :bbox => "4.5,4.5,5.5,5.5" }
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

    get :feed, :params => { :format => :atom, :display_name => user.display_name }

    assert_response :success
    assert_template "index"
    assert_equal "application/atom+xml", response.media_type

    check_feed_result(changesets)
  end

  ##
  # Check the not found of the user changesets feed
  def test_feed_user_not_found
    get :feed, :params => { :format => "atom", :display_name => "Some random user" }
    assert_response :not_found
  end

  ##
  # Check that we can't request later pages of the changesets feed
  def test_feed_max_id
    get :feed, :params => { :format => "atom", :max_id => 100 }
    assert_response :redirect
    assert_redirected_to :action => :feed
  end

  private

  ##
  # check the result of a index
  def check_index_result(changesets)
    changesets = changesets.where("num_changes > 0")
                           .order(:created_at => :desc)
                           .limit(20)
    assert changesets.size <= 20

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
