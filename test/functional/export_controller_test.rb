require File.dirname(__FILE__) + '/../test_helper'

class ExportControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  def test_start
    xhr :get, :start
    assert_response :success
    assert_template 'start'
  end
  
  def test_finish_osm
    get :finish, {:minlon => 0, :minlat => 50, :maxlon => 1, :maxlat => 51, :format => 'osm'}
    assert_response :redirect
  end
  
  def test_finish_mapnik
    get :finish, {:minlon => 0, :minlat => 50, :maxlon => 1, :maxlat => 51, :format => 'mapnik', :mapnik_format => 'test', :mapnik_scale => '12'}
    assert_response :redirect
  end
  
  def test_finish_osmarender
    get :finish, {:minlon => 0, :minlat => 50, :maxlon => 1, :maxlat => 51, :format => 'osmarender', :osmarender_format => 'test', :osmarender_zoom => '12'}
    assert_response :redirect
  end
    
end
