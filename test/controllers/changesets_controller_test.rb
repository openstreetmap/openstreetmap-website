require "test_helper"

class ChangesetsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/changeset/1", :method => :get },
      { :controller => "changesets", :action => "show", :id => "1" }
    )
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
    assert_routing(
      { :path => "/changeset/1/subscribe", :method => :get },
      { :controller => "changesets", :action => "subscribe", :id => "1" }
    )
    assert_routing(
      { :path => "/changeset/1/subscribe", :method => :post },
      { :controller => "changesets", :action => "subscribe", :id => "1" }
    )
    assert_routing(
      { :path => "/changeset/1/unsubscribe", :method => :get },
      { :controller => "changesets", :action => "unsubscribe", :id => "1" }
    )
    assert_routing(
      { :path => "/changeset/1/unsubscribe", :method => :post },
      { :controller => "changesets", :action => "unsubscribe", :id => "1" }
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
    assert_select "link[rel='alternate'][type='application/atom+xml']", :count => 1 do
      assert_select "[href=?]", "http://www.example.com/history/feed"
    end

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
    assert_select "link[rel='alternate'][type='application/atom+xml']", :count => 1 do
      assert_select "[href=?]", "http://www.example.com/history/feed"
    end

    get history_path(:format => "html", :list => "1"), :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(changesets.last(20))
  end

  ##
  # This should report an error
  def test_index_invalid_xhr
    %w[-1 0 fred].each do |id|
      get history_path(:format => "html", :list => "1", :max_id => id)
      assert_redirected_to :controller => :errors, :action => :bad_request
    end
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
    assert_select "link[rel='alternate'][type='application/atom+xml']", :count => 1 do
      assert_select "[href=?]", "http://www.example.com/history/feed?bbox=4.5%2C4.5%2C5.5%2C5.5"
    end

    get history_path(:format => "html", :bbox => "4.5,4.5,5.5,5.5", :list => "1"), :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(changesets)
  end

  ##
  # Checks the display of the user changesets listing
  def test_index_user
    user = create(:user)
    create(:changeset, :user => user, :num_changes => 1)
    create(:changeset, :closed, :user => user, :num_changes => 1)
    user.reload

    get history_path(:format => "html", :display_name => user.display_name)
    assert_response :success
    assert_template "history"
    assert_template :layout => "map"
    assert_select "h2", :text => "Changesets by #{user.display_name}", :count => 1 do
      assert_select "a[href=?]", user_path(user)
    end
    assert_select "link[rel='alternate'][type='application/atom+xml']", :count => 1 do
      assert_select "[href=?]", "http://www.example.com/user/#{ERB::Util.url_encode(user.display_name)}/history/feed"
    end

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
    assert_redirected_to login_path(:referer => friend_changesets_path)

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
    assert_redirected_to login_path(:referer => nearby_changesets_path)

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

  def test_index_timeout
    create_list(:changeset, 30, :num_changes => 1)
    with_settings(:web_timeout => -1) do
      get history_path
    end
    assert_response :success
    assert_template :layout => "map"
    assert_dom "head > link[rel='alternate'][href='#{history_feed_url}']", 1
    assert_dom "h2", "Timeout Error"
    assert_dom "p", /the list of changesets/
  end

  def test_index_list_timeout
    create_list(:changeset, 30, :num_changes => 1)
    with_settings(:web_timeout => -1) do
      get history_path(:list => "1")
    end
    assert_response :success
    assert_dom "head > link[rel='alternate'][href='#{history_feed_url}']", 0
    assert_dom "p", /the list of changesets/
  end

  def test_show
    changeset = create(:changeset)
    create(:changeset_tag, :changeset => changeset, :k => "comment", :v => "tested-changeset-comment")
    commenting_user = create(:user)
    changeset_comment = create(:changeset_comment, :changeset => changeset, :author => commenting_user, :body => "Unwanted comment")

    sidebar_browse_check :changeset_path, changeset.id, "changesets/show"
    assert_dom "h2", :text => "Changeset: #{changeset.id}"
    assert_dom "p", :text => "tested-changeset-comment"
    assert_dom "li#c#{changeset_comment.id}" do
      assert_dom "> small", :text => /^Comment from #{commenting_user.display_name}/
      assert_dom "a[href='#{user_path(commenting_user)}']"
    end
  end

  def test_show_closed_changeset
    changeset = create(:changeset, :closed)

    sidebar_browse_check :changeset_path, changeset.id, "changesets/show"
  end

  def test_show_private_changeset
    user = create(:user)
    changeset = create(:changeset, :user => create(:user, :data_public => false))
    create(:changeset, :user => user)

    sidebar_browse_check :changeset_path, changeset.id, "changesets/show"
  end

  def test_show_element_links
    changeset = create(:changeset)
    node = create(:node, :with_history, :changeset => changeset)
    way = create(:way, :with_history, :changeset => changeset)
    relation = create(:relation, :with_history, :changeset => changeset)

    sidebar_browse_check :changeset_path, changeset.id, "changesets/show"
    assert_dom "a[href='#{node_path node}']", :count => 1
    assert_dom "a[href='#{old_node_path node, 1}']", :count => 1
    assert_dom "a[href='#{way_path way}']", :count => 1
    assert_dom "a[href='#{old_way_path way, 1}']", :count => 1
    assert_dom "a[href='#{relation_path relation}']", :count => 1
    assert_dom "a[href='#{old_relation_path relation, 1}']", :count => 1
  end

  def test_show_paginated_element_links
    page_size = 20
    changeset = create(:changeset)
    nodes = create_list(:node, page_size + 1, :with_history, :changeset => changeset)
    ways = create_list(:way, page_size + 1, :with_history, :changeset => changeset)
    relations = create_list(:relation, page_size + 1, :with_history, :changeset => changeset)

    sidebar_browse_check :changeset_path, changeset.id, "changesets/show"
    page_size.times do |i|
      assert_dom "a[href='#{node_path nodes[i]}']", :count => 1
      assert_dom "a[href='#{old_node_path nodes[i], 1}']", :count => 1
      assert_dom "a[href='#{way_path ways[i]}']", :count => 1
      assert_dom "a[href='#{old_way_path ways[i], 1}']", :count => 1
      assert_dom "a[href='#{relation_path relations[i]}']", :count => 1
      assert_dom "a[href='#{old_relation_path relations[i], 1}']", :count => 1
    end
  end

  def test_show_adjacent_changesets
    user = create(:user)
    changesets = create_list(:changeset, 3, :user => user, :num_changes => 1)

    sidebar_browse_check :changeset_path, changesets[1].id, "changesets/show"
    assert_dom "a[href='#{changeset_path changesets[0]}']", :count => 1
    assert_dom "a[href='#{changeset_path changesets[2]}']", :count => 1
  end

  def test_show_adjacent_nonempty_changesets
    user = create(:user)
    changeset1 = create(:changeset, :user => user, :num_changes => 1)
    create(:changeset, :user => user, :num_changes => 0)
    changeset3 = create(:changeset, :user => user, :num_changes => 1)
    create(:changeset, :user => user, :num_changes => 0)
    changeset5 = create(:changeset, :user => user, :num_changes => 1)

    sidebar_browse_check :changeset_path, changeset3.id, "changesets/show"
    assert_dom "a[href='#{changeset_path changeset1}']", :count => 1
    assert_dom "a[href='#{changeset_path changeset5}']", :count => 1
  end

  def test_show_timeout
    changeset = create(:changeset)
    with_settings(:web_timeout => -1) do
      get changeset_path(changeset)
    end
    assert_response :success
    assert_template :layout => "map"
    assert_dom "head > link[rel='alternate'][href='#{history_feed_url}']", 0
    assert_dom "h2", "Timeout Error"
    assert_dom "p", /#{Regexp.quote("the changeset with the id #{changeset.id}")}/
  end

  ##
  # This should display the last 20 non-empty changesets
  def test_feed
    changeset = create(:changeset, :num_changes => 1)
    create(:changeset_tag, :changeset => changeset)
    create(:changeset_tag, :changeset => changeset, :k => "website", :v => "http://example.com/")
    closed_changeset = create(:changeset, :closed, :num_changes => 1)
    create(:changeset_tag, :changeset => closed_changeset, :k => "website", :v => "https://osm.org/")
    _empty_changeset = create(:changeset, :num_changes => 0)

    get history_feed_path(:format => :atom)
    assert_response :success
    assert_template "index"
    assert_equal "application/atom+xml", response.media_type

    check_feed_result([closed_changeset, changeset])
  end

  ##
  # This should correctly escape XML special characters in the comment
  def test_feed_with_comment_tag
    changeset = create(:changeset, :num_changes => 1)
    create(:changeset_tag, :changeset => changeset, :k => "comment", :v => "tested<changeset>comment")

    get history_feed_path(:format => :atom)
    assert_response :success
    assert_template "index"
    assert_equal "application/atom+xml", response.media_type

    check_feed_result([changeset])
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

    check_feed_result([closed_changeset, changeset])
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

    check_feed_result(changesets.reverse)
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
    assert_redirected_to :action => :feed
  end

  def test_feed_timeout
    with_settings(:web_timeout => -1) do
      get history_feed_path
    end
    assert_response :success
    assert_equal "application/atom+xml; charset=utf-8", @response.header["Content-Type"]
    assert_dom "feed>link[rel='self']", 1 do
      assert_dom ">@href", history_feed_url
    end
    assert_dom "feed>link[rel='alternate']", 1 do
      assert_dom ">@href", history_url
    end
    assert_dom "feed>subtitle", :text => /the list of changesets you requested took too long to retrieve/
  end

  def test_feed_bbox_timeout
    with_settings(:web_timeout => -1) do
      get history_feed_path(:bbox => "4.5,4.5,5.5,5.5")
    end
    assert_response :success
    assert_equal "application/atom+xml; charset=utf-8", @response.header["Content-Type"]
    assert_dom "feed>link[rel='self']", 1 do
      assert_dom ">@href", history_feed_url(:bbox => "4.5,4.5,5.5,5.5")
    end
    assert_dom "feed>link[rel='alternate']", 1 do
      assert_dom ">@href", history_url(:bbox => "4.5,4.5,5.5,5.5")
    end
    assert_dom "feed>subtitle", :text => /the list of changesets you requested took too long to retrieve/
  end

  def test_subscribe_page
    user = create(:user)
    other_user = create(:user)
    changeset = create(:changeset, :user => user)
    path = subscribe_changeset_path(changeset)

    get path
    assert_redirected_to login_path(:referer => path)

    session_for(other_user)
    get path
    assert_response :success
    assert_dom ".content-body" do
      assert_dom "a[href='#{changeset_path(changeset)}']", :text => "Changeset #{changeset.id}"
      assert_dom "a[href='#{user_path(user)}']", :text => user.display_name
    end
  end

  def test_subscribe_success
    user = create(:user)
    other_user = create(:user)
    changeset = create(:changeset, :user => user)

    session_for(other_user)
    assert_difference "changeset.subscribers.count", 1 do
      post subscribe_changeset_path(changeset)
    end
    assert_redirected_to changeset_path(changeset)
    assert changeset.reload.subscribed?(other_user)
  end

  def test_subscribe_fail
    user = create(:user)
    other_user = create(:user)

    changeset = create(:changeset, :user => user)

    # not signed in
    assert_no_difference "changeset.subscribers.count" do
      post subscribe_changeset_path(changeset)
    end
    assert_response :forbidden

    session_for(other_user)

    # bad diary id
    post subscribe_changeset_path(999111)
    assert_response :not_found

    # trying to subscribe when already subscribed
    post subscribe_changeset_path(changeset)
    assert_no_difference "changeset.subscribers.count" do
      post subscribe_changeset_path(changeset)
    end
  end

  def test_unsubscribe_page
    user = create(:user)
    other_user = create(:user)
    changeset = create(:changeset, :user => user)
    path = unsubscribe_changeset_path(changeset)

    get path
    assert_redirected_to login_path(:referer => path)

    session_for(other_user)
    get path
    assert_response :success
    assert_dom ".content-body" do
      assert_dom "a[href='#{changeset_path(changeset)}']", :text => "Changeset #{changeset.id}"
      assert_dom "a[href='#{user_path(user)}']", :text => user.display_name
    end
  end

  def test_unsubscribe_success
    user = create(:user)
    other_user = create(:user)

    changeset = create(:changeset, :user => user)
    changeset.subscribers.push(other_user)

    session_for(other_user)
    assert_difference "changeset.subscribers.count", -1 do
      post unsubscribe_changeset_path(changeset)
    end
    assert_redirected_to changeset_path(changeset)
    assert_not changeset.reload.subscribed?(other_user)
  end

  def test_unsubscribe_fail
    user = create(:user)
    other_user = create(:user)

    changeset = create(:changeset, :user => user)

    # not signed in
    assert_no_difference "changeset.subscribers.count" do
      post unsubscribe_changeset_path(changeset)
    end
    assert_response :forbidden

    session_for(other_user)

    # bad diary id
    post unsubscribe_changeset_path(999111)
    assert_response :not_found

    # trying to unsubscribe when not subscribed
    assert_no_difference "changeset.subscribers.count" do
      post unsubscribe_changeset_path(changeset)
    end
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
    assert_operator changesets.size, :<=, 20

    assert_select "feed", :count => [changesets.size, 1].min do
      assert_select "> title", :count => 1, :text => /^Changesets/
      assert_select "> entry", :count => changesets.size do |entries|
        entries.zip(changesets) do |entry, changeset|
          assert_select entry, "> id", :text => changeset_url(:id => changeset.id)

          changeset_comment = changeset.tags["comment"]
          if changeset_comment
            assert_select entry, "> title", :count => 1, :text => "Changeset #{changeset.id} - #{changeset_comment}"
          else
            assert_select entry, "> title", :count => 1, :text => "Changeset #{changeset.id}"
          end

          assert_select entry, "> content > xhtml|div > xhtml|table" do
            if changeset.tags.empty?
              assert_select "> xhtml|tr > xhtml|td > xhtml|table", :count => 0
            else
              assert_select "> xhtml|tr > xhtml|td > xhtml|table", :count => 1 do
                changeset.tags.each_key do |key|
                  assert_select "> xhtml|tr > xhtml|td", :text => /^#{key} = /
                end
              end
            end
          end
        end
      end
    end
  end
end
