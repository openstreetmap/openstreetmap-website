require File.dirname(__FILE__) + '/../test_helper'
require 'old_way_controller'

# Re-raise errors caught by the controller.
class OldWayController; def rescue_action(e) raise e end; end

class OldWayControllerTest < Test::Unit::TestCase
  api_fixtures

  def setup
    @controller = OldWayController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # -------------------------------------
  # Test reading old ways.
  # -------------------------------------

  def test_history
    # check that a visible way is returned properly
    get :history, :id => ways(:visible_way).id
    assert_response :success

    # check chat a non-existent way is not returned
    get :history, :id => 0
    assert_response :not_found

  end

end
