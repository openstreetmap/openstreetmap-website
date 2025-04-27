# frozen_string_literal: true

require "test_helper"

class LayersPanesControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/panes/layers", :method => :get },
      { :controller => "layers_panes", :action => "show" }
    )
  end

  def test_show
    get layers_pane_path, :xhr => true

    assert_response :success
    assert_template "layers_panes/show"
    assert_template :layout => false
  end
end
