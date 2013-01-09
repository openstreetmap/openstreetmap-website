require File.dirname(__FILE__) + '/../test_helper'

class ExportControllerTest < ActionController::TestCase

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/export/start", :method => :get },
      { :controller => "export", :action => "start" }
    )
    assert_routing(
      { :path => "/export/finish", :method => :post },
      { :controller => "export", :action => "finish" }
    )
    assert_routing(
      { :path => "/export/embed", :method => :get },
      { :controller => "export", :action => "embed" }
    )
  end

  def test_start
    xhr :get, :start
    assert_response :success
    assert_template 'export/start'
  end
  
  def test_finish_osm
    get :finish, {:minlon => 0, :minlat => 50, :maxlon => 1, :maxlat => 51, :format => 'osm'}
    assert_response :redirect
  end
  
  def test_finish_mapnik
    get :finish, {:minlon => 0, :minlat => 50, :maxlon => 1, :maxlat => 51, :format => 'mapnik', :mapnik_format => 'test', :mapnik_scale => '12'}
    assert_response :redirect
  end

end
