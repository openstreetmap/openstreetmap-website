require 'test_helper'

class ExportControllerTest < ActionController::TestCase

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/export/finish", :method => :post },
      { :controller => "export", :action => "finish" }
    )
    assert_routing(
      { :path => "/export/embed", :method => :get },
      { :controller => "export", :action => "embed" }
    )
  end

  ###
  # test the finish action for raw OSM data
  def test_finish_osm
    get :finish, {:minlon => 0, :minlat => 50, :maxlon => 1, :maxlat => 51, :format => 'osm'}
    assert_response :redirect
    assert_redirected_to "http://api.openstreetmap.org/api/#{API_VERSION}/map?bbox=0.0,50.0,1.0,51.0"
  end
  
  ###
  # test the finish action for mapnik images
  def test_finish_mapnik
    get :finish, {:minlon => 0, :minlat => 50, :maxlon => 1, :maxlat => 51, :format => 'mapnik', :mapnik_format => 'test', :mapnik_scale => '12'}
    assert_response :redirect
    assert_redirected_to "http://render.openstreetmap.org/cgi-bin/export?bbox=0.0,50.0,1.0,51.0&scale=12&format=test"
  end

  ##
  # test the embed action
  def test_embed
    get :embed
    assert_response :success
    assert_template "export/embed"
  end

end
