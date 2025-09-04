# frozen_string_literal: true

require "test_helper"

class LegendPanesControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/panes/legend", :method => :get },
      { :controller => "legend_panes", :action => "show" }
    )
  end

  def test_show
    get legend_pane_path, :xhr => true

    assert_response :success
    assert_template "legend_panes/show"
    assert_template :layout => false
  end
end
