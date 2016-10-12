require "test_helper"
require "browse_controller"

class BrowseControllerTest < ActionController::TestCase
  api_fixtures

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/node/1", :method => :get },
      { :controller => "browse", :action => "node", :id => "1" }
    )
    assert_routing(
      { :path => "/node/1/history", :method => :get },
      { :controller => "browse", :action => "node_history", :id => "1" }
    )
    assert_routing(
      { :path => "/way/1", :method => :get },
      { :controller => "browse", :action => "way", :id => "1" }
    )
    assert_routing(
      { :path => "/way/1/history", :method => :get },
      { :controller => "browse", :action => "way_history", :id => "1" }
    )
    assert_routing(
      { :path => "/relation/1", :method => :get },
      { :controller => "browse", :action => "relation", :id => "1" }
    )
    assert_routing(
      { :path => "/relation/1/history", :method => :get },
      { :controller => "browse", :action => "relation_history", :id => "1" }
    )
    assert_routing(
      { :path => "/changeset/1", :method => :get },
      { :controller => "browse", :action => "changeset", :id => "1" }
    )
    assert_routing(
      { :path => "/note/1", :method => :get },
      { :controller => "browse", :action => "note", :id => "1" }
    )
    assert_routing(
      { :path => "/note/new", :method => :get },
      { :controller => "browse", :action => "new_note" }
    )
  end

  def test_read_relation
    browse_check "relation", relations(:visible_relation).relation_id, "browse/feature"
  end

  def test_read_relation_history
    browse_check "relation_history", relations(:visible_relation).relation_id, "browse/history"
  end

  def test_read_way
    browse_check "way", ways(:visible_way).way_id, "browse/feature"
  end

  def test_read_way_history
    browse_check "way_history", ways(:visible_way).way_id, "browse/history"
  end

  def test_read_node
    browse_check "node", nodes(:visible_node).node_id, "browse/feature"
  end

  def test_read_node_history
    browse_check "node_history", nodes(:visible_node).node_id, "browse/history"
  end

  def test_read_changeset
    browse_check "changeset", changesets(:normal_user_first_change).id, "browse/changeset"
    browse_check "changeset", changesets(:public_user_first_change).id, "browse/changeset"
  end

  def test_read_changeset_hidden_comments
    create_list(:changeset_comment, 3)
    create(:changeset_comment, :visible => false)

    browse_check "changeset", changesets(:normal_user_closed_change).id, "browse/changeset"
    assert_select "div.changeset-comments ul li", :count => 3

    session[:user] = users(:moderator_user).id

    browse_check "changeset", changesets(:normal_user_closed_change).id, "browse/changeset"
    assert_select "div.changeset-comments ul li", :count => 4
  end

  def test_read_note
    open_note = create(:note_with_comments)

    browse_check "note", open_note.id, "browse/note"
  end

  def test_read_hidden_note
    hidden_note_with_comment = create(:note_with_comments, :status => "hidden")

    get :note, :id => hidden_note_with_comment.id
    assert_response :not_found
    assert_template "browse/not_found"
    assert_template :layout => "map"

    xhr :get, :note, :id => hidden_note_with_comment.id
    assert_response :not_found
    assert_template "browse/not_found"
    assert_template :layout => "xhr"

    session[:user] = users(:moderator_user).id

    browse_check "note", hidden_note_with_comment.id, "browse/note"
  end

  def test_read_note_hidden_comments
    note_with_hidden_comment = create(:note_with_comments, :comments_count => 2) do |note|
      create(:note_comment, :note => note, :visible => false)
    end

    browse_check "note", note_with_hidden_comment.id, "browse/note"
    assert_select "div.note-comments ul li", :count => 1

    session[:user] = users(:moderator_user).id

    browse_check "note", note_with_hidden_comment.id, "browse/note"
    assert_select "div.note-comments ul li", :count => 2
  end

  ##
  #  Methods to check redaction.
  #
  # note that these are presently highly reliant on the structure of the
  # page for the selection tests, which doesn't work out particularly
  # well if that structure changes. so... if you change the page layout
  # then please make it more easily (and robustly) testable!
  ##
  def test_redacted_node
    get :node, :id => current_nodes(:redacted_node).id
    assert_response :success
    assert_template "feature"

    # check that we don't show lat/lon for a redacted node.
    assert_select ".browse-section", 1
    assert_select ".browse-section.browse-node", 1
    assert_select ".browse-section.browse-node .latitude", 0
    assert_select ".browse-section.browse-node .longitude", 0
  end

  def test_redacted_node_history
    get :node_history, :id => nodes(:redacted_node_redacted_version).node_id
    assert_response :success
    assert_template "browse/history"

    # there are 2 revisions of the redacted node, but only one
    # should be showing details here.
    assert_select ".browse-section", 2
    assert_select ".browse-section.browse-redacted", 1
    assert_select ".browse-section.browse-node", 1
    assert_select ".browse-section.browse-node .latitude", 0
    assert_select ".browse-section.browse-node .longitude", 0
  end

  def test_redacted_way_history
    get :way_history, :id => ways(:way_with_redacted_versions_v1).way_id
    assert_response :success
    assert_template "browse/history"

    # there are 4 revisions of the redacted way, but only 2
    # should be showing details here.
    assert_select ".browse-section", 4
    assert_select ".browse-section.browse-redacted", 2
    assert_select ".browse-section.browse-way", 2
  end

  def test_redacted_relation_history
    get :relation_history, :id => relations(:relation_with_redacted_versions_v1).relation_id
    assert_response :success
    assert_template "browse/history"

    # there are 4 revisions of the redacted relation, but only 2
    # should be showing details here.
    assert_select ".browse-section", 4
    assert_select ".browse-section.browse-redacted", 2
    assert_select ".browse-section.browse-relation", 2
  end

  private

  # This is a convenience method for most of the above checks
  # First we check that when we don't have an id, it will correctly return a 404
  # then we check that we get the correct 404 when a non-existant id is passed
  # then we check that it will get a successful response, when we do pass an id
  def browse_check(type, id, template)
    assert_raise ActionController::UrlGenerationError do
      get type
    end

    assert_raise ActionController::UrlGenerationError do
      get type, :id => -10 # we won't have an id that's negative
    end

    get type, :id => 0
    assert_response :not_found
    assert_template "browse/not_found"
    assert_template :layout => "map"

    xhr :get, type, :id => 0
    assert_response :not_found
    assert_template "browse/not_found"
    assert_template :layout => "xhr"

    get type, :id => id
    assert_response :success
    assert_template template
    assert_template :layout => "map"

    xhr :get, type, :id => id
    assert_response :success
    assert_template template
    assert_template :layout => "xhr"
  end
end
