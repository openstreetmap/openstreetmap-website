require File.dirname(__FILE__) + '/../test_helper'
require 'old_relation_controller'

class OldRelationControllerTest < ActionController::TestCase
  api_fixtures

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
