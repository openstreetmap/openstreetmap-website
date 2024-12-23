require "test_helper"

module Features
  class KeysControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/key", :method => :get },
        { :controller => "features/keys", :action => "show" }
      )
    end

    def test_show
      get features_key_path, :xhr => true

      assert_response :success
      assert_template "features/keys/show"
      assert_template :layout => false
    end
  end
end
