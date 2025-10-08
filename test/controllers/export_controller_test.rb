# frozen_string_literal: true

require "test_helper"

class ExportControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/export/finish", :method => :post },
      { :controller => "export", :action => "create" }
    )
    assert_routing(
      { :path => "/export/embed", :method => :get },
      { :controller => "export", :action => "show" }
    )
  end

  ###
  # test the create action for raw OSM data
  def test_create_osm
    post export_finish_path(:minlon => 0, :minlat => 50, :maxlon => 1, :maxlat => 51, :format => "osm")
    assert_redirected_to api_map_path(:bbox => "0.0,50.0,1.0,51.0")
  end

  ###
  # test the create action for mapnik images
  def test_create_mapnik
    post export_finish_path(:minlon => 0, :minlat => 50, :maxlon => 1, :maxlat => 51, :format => "mapnik", :mapnik_format => "test", :mapnik_scale => "12")
    assert_redirected_to "https://render.openstreetmap.org/cgi-bin/export?bbox=0.0,50.0,1.0,51.0&scale=12&format=test&token="
  end

  ###
  # test the create action for cyclemap images
  def test_create_cyclemap
    post export_finish_path(:minlon => 0, :minlat => 50, :maxlon => 1, :maxlat => 51, :format => "cyclemap", :mapnik_scale => 12, :mapnik_format => "png", :zoom => 17, :lat => 1, :lon => 2, :width => 400, :height => 300)
    assert_redirected_to "https://tile.thunderforest.com/static/cycle/2,1,17/400x300.png?apikey=#{Settings.thunderforest_key}"
  end

  ###
  # test the create action for transport images
  def test_create_transport
    post export_finish_path(:minlon => 0, :minlat => 50, :maxlon => 1, :maxlat => 51, :format => "transportmap", :mapnik_scale => 12, :mapnik_format => "png", :zoom => 17, :lat => 1, :lon => 2, :width => 400, :height => 300)
    assert_redirected_to "https://tile.thunderforest.com/static/transport/2,1,17/400x300.png?apikey=#{Settings.thunderforest_key}"
  end

  ##
  # test the show action
  def test_show
    get export_embed_path
    assert_response :success
    assert_template "export/show"
  end
end
