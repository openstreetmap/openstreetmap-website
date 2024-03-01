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
      { :path => "/query", :method => :get },
      { :controller => "browse", :action => "query" }
    )
  end

  def test_read_relation
    relation = create(:relation)
    sidebar_browse_check :relation_path, relation.id, "browse/feature"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_relation_path relation, 1}']", :text => "1", :count => 1
    end
    assert_select ".secondary-actions a[href='#{api_relation_path relation}']", :count => 1
    assert_select ".secondary-actions a[href='#{relation_history_path relation}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_relation_path relation, 1}']", :count => 0
  end

  def test_multiple_version_relation_links
    relation = create(:relation, :with_history, :version => 2)
    sidebar_browse_check :relation_path, relation.id, "browse/feature"
    assert_select ".secondary-actions a[href='#{relation_history_path relation}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_relation_path relation, 1}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_relation_path relation, 2}']", :count => 1
  end

  def test_read_relation_history
    relation = create(:relation, :with_history)
    sidebar_browse_check :relation_history_path, relation.id, "browse/history"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_relation_path relation, 1}']", :text => "1", :count => 1
    end
  end

  def test_read_way
    way = create(:way)
    sidebar_browse_check :way_path, way.id, "browse/feature"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_way_path way, 1}']", :text => "1", :count => 1
    end
    assert_select ".secondary-actions a[href='#{api_way_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{way_history_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 1}']", :count => 0
  end

  def test_multiple_version_way_links
    way = create(:way, :with_history, :version => 2)
    sidebar_browse_check :way_path, way.id, "browse/feature"
    assert_select ".secondary-actions a[href='#{way_history_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 1}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 2}']", :count => 1
  end

  def test_read_way_history
    way = create(:way, :with_history)
    sidebar_browse_check :way_history_path, way.id, "browse/history"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_way_path way, 1}']", :text => "1", :count => 1
    end
  end

  def test_read_node
    node = create(:node)
    sidebar_browse_check :node_path, node.id, "browse/feature"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_node_path node, 1}']", :text => "1", :count => 1
    end
    assert_select ".secondary-actions a[href='#{api_node_path node}']", :count => 1
    assert_select ".secondary-actions a[href='#{node_history_path node}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_node_path node, 1}']", :count => 0
  end

  def test_multiple_version_node_links
    node = create(:node, :with_history, :version => 2)
    sidebar_browse_check :node_path, node.id, "browse/feature"
    assert_select ".secondary-actions a[href='#{node_history_path node}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_node_path node, 1}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_node_path node, 2}']", :count => 1
  end

  def test_read_deleted_node
    node = create(:node, :visible => false)
    sidebar_browse_check :node_path, node.id, "browse/feature"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_node_path node, 1}']", :text => "1", :count => 1
    end
    assert_select "a[href='#{api_node_path node}']", :count => 0
  end

  def test_read_node_history
    node = create(:node, :with_history)
    sidebar_browse_check :node_history_path, node.id, "browse/history"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_node_path node, 1}']", :text => "1", :count => 1
    end
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

  def test_redacted_node_unredacted_history
    session_for(create(:moderator_user))
    node = create(:node, :with_history, :deleted, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v1.redact!(create(:redaction))

    get node_history_path(:id => node, :params => { :show_redactions => true })
    assert_response :success
    assert_template "browse/history"

    assert_select ".browse-section", 2
    assert_select ".browse-section.browse-redacted", 0
    assert_select ".browse-section.browse-node", 2
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

  def test_redacted_way_unredacted_history
    session_for(create(:moderator_user))
    way = create(:way, :with_history, :version => 4)
    way_v1 = way.old_ways.find_by(:version => 1)
    way_v1.redact!(create(:redaction))
    way_v3 = way.old_ways.find_by(:version => 3)
    way_v3.redact!(create(:redaction))

    get way_history_path(:id => way, :params => { :show_redactions => true })
    assert_response :success
    assert_template "browse/history"

    assert_select ".browse-section", 4
    assert_select ".browse-section.browse-redacted", 0
    assert_select ".browse-section.browse-way", 4
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

  def test_redacted_relation_unredacted_history
    session_for(create(:moderator_user))
    relation = create(:relation, :with_history, :version => 4)
    relation_v1 = relation.old_relations.find_by(:version => 1)
    relation_v1.redact!(create(:redaction))
    relation_v3 = relation.old_relations.find_by(:version => 3)
    relation_v3.redact!(create(:redaction))

    get relation_history_path(:id => relation, :params => { :show_redactions => true })
    assert_response :success
    assert_template "browse/history"

    assert_select ".browse-section", 4
    assert_select ".browse-section.browse-redacted", 0
    assert_select ".browse-section.browse-relation", 4
  end

  def test_query
    get query_path
    assert_response :success
    assert_template "browse/query"
  end

  def test_anonymous_user_feature_page_secondary_actions
    node = create(:node, :with_history)
    get node_path(:id => node)
    assert_response :success
    assert_select ".secondary-actions a", :text => "View Details", :count => 0
    assert_select ".secondary-actions a", :text => "View History", :count => 1
    assert_select ".secondary-actions a", :text => "View Unredacted History", :count => 0
  end

  def test_regular_user_feature_page_secondary_actions
    session_for(create(:user))
    node = create(:node, :with_history)
    get node_path(:id => node)
    assert_response :success
    assert_select ".secondary-actions a", :text => "View Details", :count => 0
    assert_select ".secondary-actions a", :text => "View History", :count => 1
    assert_select ".secondary-actions a", :text => "View Unredacted History", :count => 0
  end

  def test_moderator_user_feature_page_secondary_actions
    session_for(create(:moderator_user))
    node = create(:node, :with_history)
    get node_path(:id => node)
    assert_response :success
    assert_select ".secondary-actions a", :text => "View Details", :count => 0
    assert_select ".secondary-actions a", :text => "View History", :count => 1
    assert_select ".secondary-actions a", :text => "View Unredacted History", :count => 1
  end

  def test_anonymous_user_history_page_secondary_actions
    node = create(:node, :with_history)
    get node_history_path(:id => node)
    assert_response :success
    assert_select ".secondary-actions a", :text => "View Details", :count => 1
    assert_select ".secondary-actions a", :text => "View History", :count => 0
    assert_select ".secondary-actions a", :text => "View Unredacted History", :count => 0
  end

  def test_regular_user_history_page_secondary_actions
    session_for(create(:user))
    node = create(:node, :with_history)
    get node_history_path(:id => node)
    assert_response :success
    assert_select ".secondary-actions a", :text => "View Details", :count => 1
    assert_select ".secondary-actions a", :text => "View History", :count => 0
    assert_select ".secondary-actions a", :text => "View Unredacted History", :count => 0
  end

  def test_moderator_user_history_page_secondary_actions
    session_for(create(:moderator_user))
    node = create(:node, :with_history)
    get node_history_path(:id => node)
    assert_response :success
    assert_select ".secondary-actions a", :text => "View Details", :count => 1
    assert_select ".secondary-actions a", :text => "View History", :count => 0
    assert_select ".secondary-actions a", :text => "View Unredacted History", :count => 1
  end

  def test_anonymous_user_unredacted_history_page_secondary_actions
    node = create(:node, :with_history)
    get node_history_path(:id => node, :params => { :show_redactions => true })
    assert_response :redirect
  end

  def test_regular_user_unredacted_history_page_secondary_actions
    session_for(create(:user))
    node = create(:node, :with_history)
    get node_history_path(:id => node, :params => { :show_redactions => true })
    assert_response :redirect
  end

  def test_moderator_user_unredacted_history_page_secondary_actions
    session_for(create(:moderator_user))
    node = create(:node, :with_history)
    get node_history_path(:id => node, :params => { :show_redactions => true })
    assert_response :success
    assert_select ".secondary-actions a", :text => "View Details", :count => 1
    assert_select ".secondary-actions a", :text => "View History", :count => 1
    assert_select ".secondary-actions a", :text => "View Unredacted History", :count => 0
  end
end
