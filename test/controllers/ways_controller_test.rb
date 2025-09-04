# frozen_string_literal: true

require "test_helper"

class WaysControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/way/1", :method => :get },
      { :controller => "ways", :action => "show", :id => "1" }
    )
  end

  def test_show
    way = create(:way)
    sidebar_browse_check :way_path, way.id, "elements/show"
  end

  def test_show_timeout
    way = create(:way)
    with_settings(:web_timeout => -1) do
      get way_path(way)
    end
    assert_response :error
    assert_template :layout => "map"
    assert_dom "h2", "Timeout Error"
    assert_dom "p", /#{Regexp.quote("the way with the id #{way.id}")}/
  end
end
