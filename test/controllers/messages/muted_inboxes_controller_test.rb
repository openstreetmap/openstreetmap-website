require "test_helper"

module Messages
  class MutedInboxesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/messages/muted", :method => :get },
        { :controller => "messages/muted_inboxes", :action => "show" }
      )
    end
  end
end
