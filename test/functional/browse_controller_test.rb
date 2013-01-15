require File.dirname(__FILE__) + '/../test_helper'
require 'browse_controller'

class BrowseControllerTest < ActionController::TestCase
  api_fixtures

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/browse/start", :method => :get },
      { :controller => "browse", :action => "start" }
    )
    assert_routing(
      { :path => "/browse/node/1", :method => :get },
      { :controller => "browse", :action => "node", :id => "1" }
    )
    assert_routing(
      { :path => "/browse/node/1/history", :method => :get },
      { :controller => "browse", :action => "node_history", :id => "1" }
    )
    assert_routing(
      { :path => "/browse/way/1", :method => :get },
      { :controller => "browse", :action => "way", :id => "1" }
    )
    assert_routing(
      { :path => "/browse/way/1/history", :method => :get },
      { :controller => "browse", :action => "way_history", :id => "1" }
    )
    assert_routing(
      { :path => "/browse/relation/1", :method => :get },
      { :controller => "browse", :action => "relation", :id => "1" }
    )
    assert_routing(
      { :path => "/browse/relation/1/history", :method => :get },
      { :controller => "browse", :action => "relation_history", :id => "1" }
    )
    assert_routing(
      { :path => "/browse/changeset/1", :method => :get },
      { :controller => "browse", :action => "changeset", :id => "1" }
    )
    assert_routing(
      { :path => "/browse/note/1", :method => :get },
      { :controller => "browse", :action => "note", :id => "1" }
    )
  end

  def test_start
    xhr :get, :start
    assert_response :success
  end

  def test_read_relation
    browse_check 'relation', relations(:visible_relation).relation_id
  end

  def test_read_relation_history
    browse_check 'relation_history', relations(:visible_relation).relation_id
  end

  def test_read_way
    browse_check 'way', ways(:visible_way).way_id
  end

  def test_read_way_history
    browse_check 'way_history', ways(:visible_way).way_id
  end

  def test_read_node
    browse_check 'node', nodes(:visible_node).node_id
  end

  def test_read_node_history
    browse_check 'node_history', nodes(:visible_node).node_id
  end

  def test_read_changeset
    browse_check 'changeset', changesets(:normal_user_first_change).id
  end

  ##
  #  Methods to check redaction.
  #
  # note that these are presently highly reliant on the structure of the
  # page for the selection tests, which doesn't work out particularly
  # well if that structure changes. so... if you change the page layout
  # then please make it more easily (and robustly) testable!
  ##
  def test_redacted_node_history
    get :node_history, :id => nodes(:redacted_node_redacted_version).node_id
    assert_response :success
    assert_template 'node_history'

    # there are 2 revisions of the redacted node, but only one
    # should be showing up here.
    assert_select "body div[id=content] div[class=browse_details]", 1
    assert_select "body div[id=content] div[class=browse_details][id=1]", 0
  end

  def test_redacted_way_history
    get :way_history, :id => ways(:way_with_redacted_versions_v1).way_id
    assert_response :success
    assert_template 'way_history'

    # there are 4 revisions of the redacted way, but only 2
    # should be showing up here.
    assert_select "body div[id=content] div[class=browse_details]", 2
    # redacted revisions are 2 & 3
    assert_select "body div[id=content] div[class=browse_details][id=2]", 0
    assert_select "body div[id=content] div[class=browse_details][id=3]", 0
  end

  def test_redacted_relation_history
    get :relation_history, :id => relations(:relation_with_redacted_versions_v1).relation_id
    assert_response :success
    assert_template 'relation_history'

    # there are 4 revisions of the redacted relation, but only 2
    # should be showing up here.
    assert_select "body div[id=content] div[class=browse_details]", 2
    # redacted revisions are 2 & 3
    assert_select "body div[id=content] div[class=browse_details][id=2]", 0
    assert_select "body div[id=content] div[class=browse_details][id=3]", 0
  end

  # This is a convenience method for most of the above checks
  # First we check that when we don't have an id, it will correctly return a 404
  # then we check that we get the correct 404 when a non-existant id is passed
  # then we check that it will get a successful response, when we do pass an id
  def browse_check(type, id)
    assert_raise ActionController::RoutingError do
      get type
    end
    assert_raise ActionController::RoutingError do
      get type, {:id => -10} # we won't have an id that's negative
    end
    get type, {:id => id}
    assert_response :success
    assert_template type
  end
end
