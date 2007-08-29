require File.dirname(__FILE__) + '/../test_helper'
require 'api_controller'

# Re-raise errors caught by the controller.
class ApiController; def rescue_action(e) raise e end; end

class ApiControllerTest < Test::Unit::TestCase
  api_fixtures

  def setup
    @controller = ApiController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def basic_authorization(user, pass)
    @request.env["HTTP_AUTHORIZATION"] = "Basic %s" % Base64.encode64("#{user}:#{pass}")
  end

  # -------------------------------------
  # Test reading a bounding box.
  # -------------------------------------

  def test_map
    node = current_nodes(:used_node_1)
    bbox = "#{node.latitude-0.1},#{node.longitude-0.1},#{node.latitude+0.1},#{node.longitude+0.1}"
    get :map, :bbox => bbox
    if $VERBOSE
        print @response.body
    end
    assert_response :success
  end

end
