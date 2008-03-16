require File.dirname(__FILE__) + '/../test_helper'
require 'old_relation_controller'

# Re-raise errors caught by the controller.
#class OldRelationController; def rescue_action(e) raise e end; end

class OldRelationControllerTest < Test::Unit::TestCase
  api_fixtures

  def setup
    @controller = OldRelationController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # -------------------------------------
  # Test reading old relations.
  # -------------------------------------

  def test_history
    # check that a visible relations is returned properly
    get :history, :id => relations(:visible_relation).id
    assert_response :success

    # check chat a non-existent relations is not returned
    get :history, :id => 0
    assert_response :not_found

  end

end
