# coding: utf-8

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

  ##
  # test the regular expressions that split search queries into 'latlon', 'us_postcode', and the like

  # latlon examples/motivation from https://trac.openstreetmap.org/ticket/4730 & https://trac.openstreetmap.org/ticket/4748
  def test_identify_latlon_degdec
    ['50.06773 14.37742', '50.06773, 14.37742', '+50.06773 +14.37742', '+50.06773, +14.37742'].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon'], assigns(:sources)
      assert_equal code, assigns(:query)
    end
  end

  ##
  # this is a test helper for rounding latlon strings to a specified precision, e.g., at a precision 
  # of 5, "50.06773333333334, -14.377416666666667" will become "50.06773, -14.37742"
  def assert_latlon_equal_round(expected, actual, precision)
    assert_equal expected.split(',').map {|i| i.to_f.round(precision)}.join(', '), actual.split(',').map {|i| i.to_f.round(precision)}.join(', ')
  end

  def test_identify_latlon_degdec_nsew
    target = '50.06773, 14.37742'
    [
        'N50.06773 E14.37742',
        'N50.06773, E14.37742',
        '50.06773N 14.37742E',
        '50.06773N, 14.37742E'
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon'], assigns(:sources)
      assert_equal target, assigns(:query)
    end
  end

  def test_identify_latlon_ddm
    target = '50.06773, 14.37742'
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
      assert_equal ['latlon'], assigns(:sources)
      assert_latlon_equal_round(target, assigns(:query), 5)
    end
  end

  def test_identify_latlon_dms
    target = '50.06773, 14.37742'
    [
        "N 50° 4' 03.828\" E 14° 22' 38.712\"",
        "N 50° 4' 03.828\", E 14° 22' 38.712\"",
        'N50 4 03.828 E14 22 38.712',
        'N50 4 03.828, E14 22 38.712',
        "50°4'3.828\"N 14°22'38.712\"E"
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon'], assigns(:sources)
      assert_equal target, assigns(:query)
    end
  end

  def test_identify_us_postcode
    ['12345', '12345-6789'].each do |code|
      post :search, query: code
      assert_response :success
      assert_equal ['us_postcode', 'osm_nominatim'], assigns(:sources)
    end
  end

  def test_identify_uk_postcode
    # examples from http://en.wikipedia.org/wiki/Postcodes_in_the_United_Kingdom
    ['EC1A 1BB', 'W1A 1HQ', 'M1 1AA', 'B33 8TH', 'CR2 6XH', 'DN55 1PT'].each do |code|
      post :search, query: code
      assert_response :success
      assert_equal ['uk_postcode', 'osm_nominatim'], assigns(:sources)
    end
  end

  def test_identify_ca_postcode
    post :search, query: 'A1B 2C3'
    assert_response :success
    assert_equal ['ca_postcode', 'osm_nominatim'], assigns(:sources)
  end

  def test_identify_fall_through_no_geonames
    post :search, query: 'foo bar baz'
    assert_response :success
    assert_equal ['osm_nominatim'], assigns(:sources)
  end

  def test_ne
    target = '50.06773, 14.37742'
    [
        "N 50° 04.064', E 014° 22.645'",
        "N 50° 4' 03.828\", E 14° 22' 38.712\"",
        "50°4'3.828\"N 14°22'38.712\"E",
        "50° 04.064' N, 014° 22.645' E"
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon'], assigns(:sources)
      assert_latlon_equal_round(target, assigns(:query), 5)
    end
  end

  def test_nw
    target = '50.06773, -14.37742'
    [
        "N 50° 04.064', W 014° 22.645'",
        "N 50° 4' 03.828\", W 14° 22' 38.712\"",
        "50°4'3.828\"N 14°22'38.712\"W",
        "50° 04.064' N, 014° 22.645' W"
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon'], assigns(:sources)
      assert_latlon_equal_round(target, assigns(:query), 5)
    end
  end

  def test_se
    target = '-50.06773, 14.37742'
    [
        "S 50° 04.064', E 014° 22.645'",
        "S 50° 4' 03.828\", E 14° 22' 38.712\"",
        "50°4'3.828\"S 14°22'38.712\"E",
        "50° 04.064' S, 014° 22.645' E"
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon'], assigns(:sources)
      assert_latlon_equal_round(target, assigns(:query), 5)
    end
  end

  def test_sw
    target = '-50.06773, -14.37742'
    [
        "S 50° 04.064', W 014° 22.645'",
        "S 50° 4' 03.828\", W 14° 22' 38.712\"",
        "50°4'3.828\"S 14°22'38.712\"W",
        "50° 04.064' S, 014° 22.645' W"
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon'], assigns(:sources)
      assert_latlon_equal_round(target, assigns(:query), 5)
    end
  end

  def test_primes_and_double_primes
    target = '50.06773, -14.37742'
    [
        "N 50° 4′ 03.828″, W 14° 22′ 38.712″"
    ].each do |code|
      post :search, :query => code
      assert_response :success
      assert_equal ['latlon'], assigns(:sources)
      assert_equal target, assigns(:query)
    end
  end
end
