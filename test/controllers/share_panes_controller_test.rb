# frozen_string_literal: true

require "test_helper"

class SharePanesControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/panes/share", :method => :get },
      { :controller => "share_panes", :action => "show" }
    )
  end

  def test_show
    get share_pane_path, :xhr => true

    assert_response :success
    assert_template "share_panes/show"
    assert_template :layout => false
  end
end
