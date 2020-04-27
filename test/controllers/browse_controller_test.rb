require "test_helper"

class BrowseControllerTest < ActionDispatch::IntegrationTest
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
    assert_routing(
      { :path => "/query", :method => :get },
      { :controller => "browse", :action => "query" }
    )
  end

  def test_read_relation
    browse_check :relation_path, create(:relation).id, "browse/feature"
  end

  def test_read_relation_history
    browse_check :relation_history_path, create(:relation, :with_history).id, "browse/history"
  end

  def test_read_way
    browse_check :way_path, create(:way).id, "browse/feature"
  end

  def test_read_way_history
    browse_check :way_history_path, create(:way, :with_history).id, "browse/history"
  end

  def test_read_node
    browse_check :node_path, create(:node).id, "browse/feature"
  end

  def test_read_node_history
    browse_check :node_history_path, create(:node, :with_history).id, "browse/history"
  end

  def test_read_changeset
    user = create(:user)
    changeset = create(:changeset, :user => user)
    create(:changeset, :user => user)
    browse_check :changeset_path, changeset.id, "browse/changeset"
  end

  def test_read_private_changeset
    user = create(:user)
    changeset = create(:changeset, :user => create(:user, :data_public => false))
    create(:changeset, :user => user)
    browse_check :changeset_path, changeset.id, "browse/changeset"
  end

  def test_read_changeset_hidden_comments
    changeset = create(:changeset)
    create_list(:changeset_comment, 3, :changeset => changeset)
    create(:changeset_comment, :visible => false, :changeset => changeset)

    browse_check :changeset_path, changeset.id, "browse/changeset"
    assert_select "div.changeset-comments ul li", :count => 3

    session_for(create(:moderator_user))

    browse_check :changeset_path, changeset.id, "browse/changeset"
    assert_select "div.changeset-comments ul li", :count => 4
  end

  def test_read_note
    open_note = create(:note_with_comments)

    browse_check :browse_note_path, open_note.id, "browse/note"
  end

  def test_read_hidden_note
    hidden_note_with_comment = create(:note_with_comments, :status => "hidden")

    get browse_note_path(:id => hidden_note_with_comment)
    assert_response :not_found
    assert_template "browse/not_found"
    assert_template :layout => "map"

    get browse_note_path(:id => hidden_note_with_comment), :xhr => true
    assert_response :not_found
    assert_template "browse/not_found"
    assert_template :layout => "xhr"

    session_for(create(:moderator_user))

    browse_check :browse_note_path, hidden_note_with_comment.id, "browse/note"
  end

  def test_read_note_hidden_comments
    note_with_hidden_comment = create(:note_with_comments, :comments_count => 2) do |note|
      create(:note_comment, :note => note, :visible => false)
    end

    browse_check :browse_note_path, note_with_hidden_comment.id, "browse/note"
    assert_select "div.note-comments ul li", :count => 1

    session_for(create(:moderator_user))

    browse_check :browse_note_path, note_with_hidden_comment.id, "browse/note"
    assert_select "div.note-comments ul li", :count => 2
  end

  def test_read_note_hidden_user_comment
    hidden_user = create(:user, :status => "deleted")
    note_with_hidden_user_comment = create(:note_with_comments, :comments_count => 2) do |note|
      create(:note_comment, :note => note, :author => hidden_user)
    end

    browse_check :browse_note_path, note_with_hidden_user_comment.id, "browse/note"
    assert_select "div.note-comments ul li", :count => 1

    session_for(create(:moderator_user))

    browse_check :browse_note_path, note_with_hidden_user_comment.id, "browse/note"
    assert_select "div.note-comments ul li", :count => 1
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
    node = create(:node, :with_history, :deleted, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v1.redact!(create(:redaction))

    get node_path(:id => node)
    assert_response :success
    assert_template "feature"

    # check that we don't show lat/lon for a redacted node.
    assert_select ".browse-section", 1
    assert_select ".browse-section.browse-node", 1
    assert_select ".browse-section.browse-node .latitude", 0
    assert_select ".browse-section.browse-node .longitude", 0
  end

  def test_redacted_node_history
    node = create(:node, :with_history, :deleted, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v1.redact!(create(:redaction))

    get node_history_path(:id => node)
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
    way = create(:way, :with_history, :version => 4)
    way_v1 = way.old_ways.find_by(:version => 1)
    way_v1.redact!(create(:redaction))
    way_v3 = way.old_ways.find_by(:version => 3)
    way_v3.redact!(create(:redaction))

    get way_history_path(:id => way)
    assert_response :success
    assert_template "browse/history"

    # there are 4 revisions of the redacted way, but only 2
    # should be showing details here.
    assert_select ".browse-section", 4
    assert_select ".browse-section.browse-redacted", 2
    assert_select ".browse-section.browse-way", 2
  end

  def test_redacted_relation_history
    relation = create(:relation, :with_history, :version => 4)
    relation_v1 = relation.old_relations.find_by(:version => 1)
    relation_v1.redact!(create(:redaction))
    relation_v3 = relation.old_relations.find_by(:version => 3)
    relation_v3.redact!(create(:redaction))

    get relation_history_path(:id => relation)
    assert_response :success
    assert_template "browse/history"

    # there are 4 revisions of the redacted relation, but only 2
    # should be showing details here.
    assert_select ".browse-section", 4
    assert_select ".browse-section.browse-redacted", 2
    assert_select ".browse-section.browse-relation", 2
  end

  def test_new_note
    get note_new_path
    assert_response :success
    assert_template "browse/new_note"
  end

  def test_query
    get query_path
    assert_response :success
    assert_template "browse/query"
  end

  private

  # This is a convenience method for most of the above checks
  # First we check that when we don't have an id, it will correctly return a 404
  # then we check that we get the correct 404 when a non-existant id is passed
  # then we check that it will get a successful response, when we do pass an id
  def browse_check(path, id, template)
    path_method = method(path)

    assert_raise ActionController::UrlGenerationError do
      get path_method.call
    end

    assert_raise ActionController::UrlGenerationError do
      get path_method.call(:id => -10) # we won't have an id that's negative
    end

    get path_method.call(:id => 0)
    assert_response :not_found
    assert_template "browse/not_found"
    assert_template :layout => "map"

    get path_method.call(:id => 0), :xhr => true
    assert_response :not_found
    assert_template "browse/not_found"
    assert_template :layout => "xhr"

    get path_method.call(:id => id)
    assert_response :success
    assert_template template
    assert_template :layout => "map"

    get path_method.call(:id => id), :xhr => true
    assert_response :success
    assert_template template
    assert_template :layout => "xhr"
  end
end
