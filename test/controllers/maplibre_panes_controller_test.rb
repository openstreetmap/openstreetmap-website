# frozen_string_literal: true

require "test_helper"

class MaplibrePanesControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/panes/maplibre/webgl_error", :method => :get },
      { :controller => "maplibre_panes", :action => "show" }
    )
  end

  def test_show
    get maplibre_pane_path, :xhr => true

    assert_response :success
    assert_template "maplibre_panes/show"
    assert_template :layout => false
    assert_select "div.maplibre-error"
  end
end
