require "test_helper"

class ChangesetCommentsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/name/history/comments", :method => :get },
      { :controller => "changeset_comments", :action => "index", :display_name => "name" }
    )
  end
end
