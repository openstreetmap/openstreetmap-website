require File.dirname(__FILE__) + '/../test_helper'
require 'old_relation_controller'

class OldRelationControllerTest < ActionController::TestCase
  api_fixtures

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/relation/1/history", :method => :get },
      { :controller => "old_relation", :action => "history", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/relation/1/2", :method => :get },
      { :controller => "old_relation", :action => "version", :id => "1", :version => "2" }
    )
  end

  # -------------------------------------
  # Test reading old relations.
  # -------------------------------------
  def test_history
    # check that a visible relations is returned properly
    get :history, :id => relations(:visible_relation).relation_id
    assert_response :success

    # check chat a non-existent relations is not returned
    get :history, :id => 0
    assert_response :not_found
  end
end
