# coding: utf-8

require File.dirname(__FILE__) + '/../test_helper'
require 'geocoder_controller'

class GeocoderControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/search", :method => :get },
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
      { :path => "/geocoder/search_osm_nominatim", :method => :get },
      { :controller => "geocoder", :action => "search_osm_nominatim" }
    )
    assert_routing(
      { :path => "/geocoder/search_geonames", :method => :get },
      { :controller => "geocoder", :action => "search_geonames" }
    )
    assert_routing(
      { :path => "/geocoder/search_osm_nominatim_reverse", :method => :get },
      { :controller => "geocoder", :action => "search_osm_nominatim_reverse" }
    )
    assert_routing(
      { :path => "/geocoder/search_geonames_reverse", :method => :get },
      { :controller => "geocoder", :action => "search_geonames_reverse" }
    )
  end

  ##
  # Test identification of basic lat/lon pairs
  def test_identify_latlon_basic
    [
     '50.06773 14.37742',
     '50.06773, 14.37742',
     '+50.06773 +14.37742',
     '+50.06773, +14.37742'
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon' ,'osm_nominatim_reverse', 'geonames_reverse'], assigns(:sources)
      assert_nil @controller.params[:query]
      assert_in_delta 50.06773, @controller.params[:lat]
      assert_in_delta 14.37742, @controller.params[:lon]
    end
  end

  ##
  # Test identification of lat/lon pairs using N/E with degrees
  def test_identify_latlon_ne_d
    [
     'N50.06773 E14.37742',
     'N50.06773, E14.37742',
     '50.06773N 14.37742E',
     '50.06773N, 14.37742E'
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon' ,'osm_nominatim_reverse', 'geonames_reverse'], assigns(:sources)
      assert_nil @controller.params[:query]
      assert_in_delta 50.06773, @controller.params[:lat]
      assert_in_delta 14.37742, @controller.params[:lon]
    end
  end

  ##
  # Test identification of lat/lon pairs using N/W with degrees
  def test_identify_latlon_nw_d
    [
     'N50.06773 W14.37742',
     'N50.06773, W14.37742',
     '50.06773N 14.37742W',
     '50.06773N, 14.37742W'
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon' ,'osm_nominatim_reverse', 'geonames_reverse'], assigns(:sources)
      assert_nil @controller.params[:query]
      assert_in_delta 50.06773, @controller.params[:lat]
      assert_in_delta -14.37742, @controller.params[:lon]
    end
  end

  ##
  # Test identification of lat/lon pairs using S/E with degrees
  def test_identify_latlon_se_d
    [
     'S50.06773 E14.37742',
     'S50.06773, E14.37742',
     '50.06773S 14.37742E',
     '50.06773S, 14.37742E'
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon' ,'osm_nominatim_reverse', 'geonames_reverse'], assigns(:sources)
      assert_nil @controller.params[:query]
      assert_in_delta -50.06773, @controller.params[:lat]
      assert_in_delta 14.37742, @controller.params[:lon]
    end
  end

  ##
  # Test identification of lat/lon pairs using S/W with degrees
  def test_identify_latlon_sw_d
    [
     'S50.06773 W14.37742',
     'S50.06773, W14.37742',
     '50.06773S 14.37742W',
     '50.06773S, 14.37742W'
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon' ,'osm_nominatim_reverse', 'geonames_reverse'], assigns(:sources)
      assert_nil @controller.params[:query]
      assert_in_delta -50.06773, @controller.params[:lat]
      assert_in_delta -14.37742, @controller.params[:lon]
    end
  end

  ##
  # Test identification of lat/lon pairs using N/E with degrees/mins
  def test_identify_latlon_ne_dm
    [
     'N 50° 04.064 E 014° 22.645',
     "N 50° 04.064' E 014° 22.645",
     "N 50° 04.064', E 014° 22.645'",
     'N50° 04.064 E14° 22.645',
     'N 50 04.064 E 014 22.645',
     'N50 4.064 E14 22.645',
     "50° 04.064' N, 014° 22.645' E"
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon' ,'osm_nominatim_reverse', 'geonames_reverse'], assigns(:sources)
      assert_nil @controller.params[:query]
      assert_in_delta 50.06773, @controller.params[:lat]
      assert_in_delta 14.37742, @controller.params[:lon]
    end
  end

  ##
  # Test identification of lat/lon pairs using N/W with degrees/mins
  def test_identify_latlon_nw_dm
    [
     'N 50° 04.064 W 014° 22.645',
     "N 50° 04.064' W 014° 22.645",
     "N 50° 04.064', W 014° 22.645'",
     'N50° 04.064 W14° 22.645',
     'N 50 04.064 W 014 22.645',
     'N50 4.064 W14 22.645',
     "50° 04.064' N, 014° 22.645' W"
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon' ,'osm_nominatim_reverse', 'geonames_reverse'], assigns(:sources)
      assert_nil @controller.params[:query]
      assert_in_delta 50.06773, @controller.params[:lat]
      assert_in_delta -14.37742, @controller.params[:lon]
    end
  end

  ##
  # Test identification of lat/lon pairs using S/E with degrees/mins
  def test_identify_latlon_se_dm
    [
     'S 50° 04.064 E 014° 22.645',
     "S 50° 04.064' E 014° 22.645",
     "S 50° 04.064', E 014° 22.645'",
     'S50° 04.064 E14° 22.645',
     'S 50 04.064 E 014 22.645',
     'S50 4.064 E14 22.645',
     "50° 04.064' S, 014° 22.645' E"
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon' ,'osm_nominatim_reverse', 'geonames_reverse'], assigns(:sources)
      assert_nil @controller.params[:query]
      assert_in_delta -50.06773, @controller.params[:lat]
      assert_in_delta 14.37742, @controller.params[:lon]
    end
  end

  ##
  # Test identification of lat/lon pairs using S/W with degrees/mins
  def test_identify_latlon_sw_dm
    [
     'S 50° 04.064 W 014° 22.645',
     "S 50° 04.064' W 014° 22.645",
     "S 50° 04.064', W 014° 22.645'",
     'S50° 04.064 W14° 22.645',
     'S 50 04.064 W 014 22.645',
     'S50 4.064 W14 22.645',
     "50° 04.064' S, 014° 22.645' W"
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon' ,'osm_nominatim_reverse', 'geonames_reverse'], assigns(:sources)
      assert_nil @controller.params[:query]
      assert_in_delta -50.06773, @controller.params[:lat]
      assert_in_delta -14.37742, @controller.params[:lon]
    end
  end

  ##
  # Test identification of lat/lon pairs using N/E with degrees/mins/secs
  def test_identify_latlon_ne_dms
    [
     "N 50° 4' 03.828\" E 14° 22' 38.712\"",
     "N 50° 4' 03.828\", E 14° 22' 38.712\"",
     "N 50° 4′ 03.828″, E 14° 22′ 38.712″",
     'N50 4 03.828 E14 22 38.712',
     'N50 4 03.828, E14 22 38.712',
     "50°4'3.828\"N 14°22'38.712\"E"
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon' ,'osm_nominatim_reverse', 'geonames_reverse'], assigns(:sources)
      assert_nil @controller.params[:query]
      assert_in_delta 50.06773, @controller.params[:lat]
      assert_in_delta 14.37742, @controller.params[:lon]
    end
  end

  ##
  # Test identification of lat/lon pairs using N/W with degrees/mins/secs
  def test_identify_latlon_nw_dms
    [
     "N 50° 4' 03.828\" W 14° 22' 38.712\"",
     "N 50° 4' 03.828\", W 14° 22' 38.712\"",
     "N 50° 4′ 03.828″, W 14° 22′ 38.712″",
     'N50 4 03.828 W14 22 38.712',
     'N50 4 03.828, W14 22 38.712',
     "50°4'3.828\"N 14°22'38.712\"W"
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon' ,'osm_nominatim_reverse', 'geonames_reverse'], assigns(:sources)
      assert_nil @controller.params[:query]
      assert_in_delta 50.06773, @controller.params[:lat]
      assert_in_delta -14.37742, @controller.params[:lon]
    end
  end

  ##
  # Test identification of lat/lon pairs using S/E with degrees/mins/secs
  def test_identify_latlon_se_dms
    [
     "S 50° 4' 03.828\" E 14° 22' 38.712\"",
     "S 50° 4' 03.828\", E 14° 22' 38.712\"",
     "S 50° 4′ 03.828″, E 14° 22′ 38.712″",
     'S50 4 03.828 E14 22 38.712',
     'S50 4 03.828, E14 22 38.712',
     "50°4'3.828\"S 14°22'38.712\"E"
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon' ,'osm_nominatim_reverse', 'geonames_reverse'], assigns(:sources)
      assert_nil @controller.params[:query]
      assert_in_delta -50.06773, @controller.params[:lat]
      assert_in_delta 14.37742, @controller.params[:lon]
    end
  end

  ##
  # Test identification of lat/lon pairs using S/W with degrees/mins/secs
  def test_identify_latlon_sw_dms
    [
     "S 50° 4' 03.828\" W 14° 22' 38.712\"",
     "S 50° 4' 03.828\", W 14° 22' 38.712\"",
     "S 50° 4′ 03.828″, W 14° 22′ 38.712″",
     'S50 4 03.828 W14 22 38.712',
     'S50 4 03.828, W14 22 38.712',
     "50°4'3.828\"S 14°22'38.712\"W"
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon' ,'osm_nominatim_reverse', 'geonames_reverse'], assigns(:sources)
      assert_nil @controller.params[:query]
      assert_in_delta -50.06773, @controller.params[:lat]
      assert_in_delta -14.37742, @controller.params[:lon]
    end
  end

  ##
  # Test identification of US zipcodes
  def test_identify_us_postcode
    [
     '12345',
     '12345-6789'
    ].each do |code|
      post :search, query: code
      assert_response :success
      assert_equal ['us_postcode', 'osm_nominatim'], assigns(:sources)
    end
  end

  ##
  # Test identification of UK postcodes using examples from 
  # http://en.wikipedia.org/wiki/Postcodes_in_the_United_Kingdom
  def test_identify_uk_postcode
    [
     'EC1A 1BB',
     'W1A 1HQ',
     'M1 1AA',
     'B33 8TH',
     'CR2 6XH',
     'DN55 1PT'
    ].each do |code|
      post :search, query: code
      assert_response :success
      assert_equal ['uk_postcode', 'osm_nominatim'], assigns(:sources)
    end
  end

  ##
  # Test identification of Canadian postcodes
  def test_identify_ca_postcode
    post :search, query: 'A1B 2C3'
    assert_response :success
    assert_equal ['ca_postcode', 'osm_nominatim'], assigns(:sources)
  end

  ##
  # Test identification fall through to the default case
  def test_identify_default
    post :search, query: 'foo bar baz'
    assert_response :success
    assert_equal ['osm_nominatim'], assigns(:sources)
  end
end
