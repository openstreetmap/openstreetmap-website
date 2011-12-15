require File.dirname(__FILE__) + '/../test_helper'
require 'browse_controller'

class BrowseControllerTest < ActionController::TestCase
  api_fixtures

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
  
  # This is a convenience method for most of the above checks
  # First we check that when we don't have an id, it will correctly return a 404
  # then we check that we get the correct 404 when a non-existant id is passed
  # then we check that it will get a successful response, when we do pass an id
  def browse_check(type, id) 
    get type
    assert_response :not_found
    assert_template 'not_found'
    get type, {:id => -10} # we won't have an id that's negative
    assert_response :not_found
    assert_template 'not_found'
    get type, {:id => id}
    assert_response :success
    assert_template type
  end
end
