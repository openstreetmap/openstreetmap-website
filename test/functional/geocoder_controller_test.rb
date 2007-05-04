require File.dirname(__FILE__) + '/../test_helper'
require 'geocoder_controller'

# Re-raise errors caught by the controller.
class GeocoderController; def rescue_action(e) raise e end; end

class GeocoderControllerTest < Test::Unit::TestCase
  def setup
    @controller = GeocoderController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
