# frozen_string_literal: true

require "test_helper"

class WebglErrorPanesControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/panes/webgl_error", :method => :get },
      { :controller => "webgl_error_panes", :action => "show" }
    )
  end

  def test_show
    get webgl_error_pane_path, :xhr => true

    assert_response :success
    assert_template "webgl_error_panes/show"
    assert_template :layout => false
    assert_select "div.maplibre-error"
  end
end
