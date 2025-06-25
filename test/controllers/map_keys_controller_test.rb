require "test_helper"

class MapKeysControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/key", :method => :get },
      { :controller => "map_keys", :action => "show" }
    )
  end

  def test_show
    get map_key_path, :xhr => true

    assert_response :success
    assert_template "map_keys/show"
    assert_template :layout => false
  end
end
