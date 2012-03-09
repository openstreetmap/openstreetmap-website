require File.dirname(__FILE__) + '/../test_helper'
require 'geocoder_controller'

class GeocoderControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/geocoder/search", :method => :post },
      { :controller => "geocoder", :action => "search" }
    )
    assert_routing(
      { :path => "/geocoder/search_latlon", :method => :get },
      { :controller => "geocoder", :action => "search_latlon" }
    )
    assert_routing(
      { :path => "/geocoder/search_us_postcode", :method => :get },
      { :controller => "geocoder", :action => "search_us_postcode" }
    )
    assert_routing(
      { :path => "/geocoder/search_uk_postcode", :method => :get },
      { :controller => "geocoder", :action => "search_uk_postcode" }
    )
    assert_routing(
      { :path => "/geocoder/search_ca_postcode", :method => :get },
      { :controller => "geocoder", :action => "search_ca_postcode" }
    )
    assert_routing(
      { :path => "/geocoder/search_osm_namefinder", :method => :get },
      { :controller => "geocoder", :action => "search_osm_namefinder" }
    )
    assert_routing(
      { :path => "/geocoder/search_osm_nominatim", :method => :get },
      { :controller => "geocoder", :action => "search_osm_nominatim" }
    )
    assert_routing(
      { :path => "/geocoder/search_geonames", :method => :get },
      { :controller => "geocoder", :action => "search_geonames" }
    )

    assert_routing(
      { :path => "/geocoder/description", :method => :post },
      { :controller => "geocoder", :action => "description" }
    )
    assert_routing(
      { :path => "/geocoder/description_osm_namefinder", :method => :get },
      { :controller => "geocoder", :action => "description_osm_namefinder" }
    )
    assert_routing(
      { :path => "/geocoder/description_osm_nominatim", :method => :get },
      { :controller => "geocoder", :action => "description_osm_nominatim" }
    )
    assert_routing(
      { :path => "/geocoder/description_geonames", :method => :get },
      { :controller => "geocoder", :action => "description_geonames" }
    )
  end
end
