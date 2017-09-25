# coding: utf-8

require "test_helper"
require "geocoder_controller"

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
  # Test identification with no arguments
  def test_identify_error
    get :search
    assert_response :bad_request

    get :search, :xhr => true
    assert_response :bad_request
  end

  ##
  # Test identification of basic lat/lon pairs
  def test_identify_latlon_basic
    [
      "50.06773 14.37742",
      "50.06773, 14.37742",
      "+50.06773 +14.37742",
      "+50.06773, +14.37742"
    ].each do |code|
      latlon_check code, 50.06773, 14.37742
    end
  end

  ##
  # Test identification of lat/lon pairs using N/E with degrees
  def test_identify_latlon_ne_d
    [
      "N50.06773 E14.37742",
      "N50.06773, E14.37742",
      "50.06773N 14.37742E",
      "50.06773N, 14.37742E"
    ].each do |code|
      latlon_check code, 50.06773, 14.37742
    end
  end

  ##
  # Test identification of lat/lon pairs using N/W with degrees
  def test_identify_latlon_nw_d
    [
      "N50.06773 W14.37742",
      "N50.06773, W14.37742",
      "50.06773N 14.37742W",
      "50.06773N, 14.37742W"
    ].each do |code|
      latlon_check code, 50.06773, -14.37742
    end
  end

  ##
  # Test identification of lat/lon pairs using S/E with degrees
  def test_identify_latlon_se_d
    [
      "S50.06773 E14.37742",
      "S50.06773, E14.37742",
      "50.06773S 14.37742E",
      "50.06773S, 14.37742E"
    ].each do |code|
      latlon_check code, -50.06773, 14.37742
    end
  end

  ##
  # Test identification of lat/lon pairs using S/W with degrees
  def test_identify_latlon_sw_d
    [
      "S50.06773 W14.37742",
      "S50.06773, W14.37742",
      "50.06773S 14.37742W",
      "50.06773S, 14.37742W"
    ].each do |code|
      latlon_check code, -50.06773, -14.37742
    end
  end

  ##
  # Test identification of lat/lon pairs using N/E with degrees/mins
  def test_identify_latlon_ne_dm
    [
      "N 50° 04.064 E 014° 22.645",
      "N 50° 04.064' E 014° 22.645",
      "N 50° 04.064', E 014° 22.645'",
      "N50° 04.064 E14° 22.645",
      "N 50 04.064 E 014 22.645",
      "N50 4.064 E14 22.645",
      "50° 04.064' N, 014° 22.645' E"
    ].each do |code|
      latlon_check code, 50.06773, 14.37742
    end
  end

  ##
  # Test identification of lat/lon pairs using N/W with degrees/mins
  def test_identify_latlon_nw_dm
    [
      "N 50° 04.064 W 014° 22.645",
      "N 50° 04.064' W 014° 22.645",
      "N 50° 04.064', W 014° 22.645'",
      "N50° 04.064 W14° 22.645",
      "N 50 04.064 W 014 22.645",
      "N50 4.064 W14 22.645",
      "50° 04.064' N, 014° 22.645' W"
    ].each do |code|
      latlon_check code, 50.06773, -14.37742
    end
  end

  ##
  # Test identification of lat/lon pairs using S/E with degrees/mins
  def test_identify_latlon_se_dm
    [
      "S 50° 04.064 E 014° 22.645",
      "S 50° 04.064' E 014° 22.645",
      "S 50° 04.064', E 014° 22.645'",
      "S50° 04.064 E14° 22.645",
      "S 50 04.064 E 014 22.645",
      "S50 4.064 E14 22.645",
      "50° 04.064' S, 014° 22.645' E"
    ].each do |code|
      latlon_check code, -50.06773, 14.37742
    end
  end

  ##
  # Test identification of lat/lon pairs using S/W with degrees/mins
  def test_identify_latlon_sw_dm
    [
      "S 50° 04.064 W 014° 22.645",
      "S 50° 04.064' W 014° 22.645",
      "S 50° 04.064', W 014° 22.645'",
      "S50° 04.064 W14° 22.645",
      "S 50 04.064 W 014 22.645",
      "S50 4.064 W14 22.645",
      "50° 04.064' S, 014° 22.645' W"
    ].each do |code|
      latlon_check code, -50.06773, -14.37742
    end
  end

  ##
  # Test identification of lat/lon pairs using N/E with degrees/mins/secs
  def test_identify_latlon_ne_dms
    [
      "N 50° 4' 03.828\" E 14° 22' 38.712\"",
      "N 50° 4' 03.828\", E 14° 22' 38.712\"",
      "N 50° 4′ 03.828″, E 14° 22′ 38.712″",
      "N50 4 03.828 E14 22 38.712",
      "N50 4 03.828, E14 22 38.712",
      "50°4'3.828\"N 14°22'38.712\"E"
    ].each do |code|
      latlon_check code, 50.06773, 14.37742
    end
  end

  ##
  # Test identification of lat/lon pairs using N/W with degrees/mins/secs
  def test_identify_latlon_nw_dms
    [
      "N 50° 4' 03.828\" W 14° 22' 38.712\"",
      "N 50° 4' 03.828\", W 14° 22' 38.712\"",
      "N 50° 4′ 03.828″, W 14° 22′ 38.712″",
      "N50 4 03.828 W14 22 38.712",
      "N50 4 03.828, W14 22 38.712",
      "50°4'3.828\"N 14°22'38.712\"W"
    ].each do |code|
      latlon_check code, 50.06773, -14.37742
    end
  end

  ##
  # Test identification of lat/lon pairs using S/E with degrees/mins/secs
  def test_identify_latlon_se_dms
    [
      "S 50° 4' 03.828\" E 14° 22' 38.712\"",
      "S 50° 4' 03.828\", E 14° 22' 38.712\"",
      "S 50° 4′ 03.828″, E 14° 22′ 38.712″",
      "S50 4 03.828 E14 22 38.712",
      "S50 4 03.828, E14 22 38.712",
      "50°4'3.828\"S 14°22'38.712\"E"
    ].each do |code|
      latlon_check code, -50.06773, 14.37742
    end
  end

  ##
  # Test identification of lat/lon pairs using S/W with degrees/mins/secs
  def test_identify_latlon_sw_dms
    [
      "S 50° 4' 03.828\" W 14° 22' 38.712\"",
      "S 50° 4' 03.828\", W 14° 22' 38.712\"",
      "S 50° 4′ 03.828″, W 14° 22′ 38.712″",
      "S50 4 03.828 W14 22 38.712",
      "S50 4 03.828, W14 22 38.712",
      "50°4'3.828\"S 14°22'38.712\"W"
    ].each do |code|
      latlon_check code, -50.06773, -14.37742
    end
  end

  ##
  # Test identification of US zipcodes
  def test_identify_us_postcode
    [
      "12345",
      "12345-6789"
    ].each do |code|
      post :search, :params => { :query => code }
      assert_response :success
      assert_equal %w[osm_nominatim], assigns(:sources)
    end
  end

  ##
  # Test identification of UK postcodes using examples from
  # http://en.wikipedia.org/wiki/Postcodes_in_the_United_Kingdom
  def test_identify_uk_postcode
    [
      "EC1A 1BB",
      "W1A 1HQ",
      "M1 1AA",
      "B33 8TH",
      "CR2 6XH",
      "DN55 1PT"
    ].each do |code|
      search_check code, %w[uk_postcode osm_nominatim]
    end
  end

  ##
  # Test identification of Canadian postcodes
  def test_identify_ca_postcode
    search_check "A1B 2C3", %w[ca_postcode osm_nominatim]
  end

  ##
  # Test identification fall through to the default case
  def test_identify_default
    search_check "foo bar baz", %w[osm_nominatim geonames]
  end

  ##
  # Test the builtin latitude+longitude search
  def test_search_latlon
    get :search_latlon, :params => { :lat => 1.23, :lon => 4.56, :zoom => 16 }, :xhr => true
    results_check :name => "1.23, 4.56", :lat => 1.23, :lon => 4.56, :zoom => 16

    get :search_latlon, :params => { :lat => -91.23, :lon => 4.56, :zoom => 16 }, :xhr => true
    results_check_error "Latitude -91.23 out of range"

    get :search_latlon, :params => { :lat => 91.23, :lon => 4.56, :zoom => 16 }, :xhr => true
    results_check_error "Latitude 91.23 out of range"

    get :search_latlon, :params => { :lat => 1.23, :lon => -180.23, :zoom => 16 }, :xhr => true
    results_check_error "Longitude -180.23 out of range"

    get :search_latlon, :params => { :lat => 1.23, :lon => 180.23, :zoom => 16 }, :xhr => true
    results_check_error "Longitude 180.23 out of range"
  end

  ##
  # Test the UK postcode search
  def test_search_uk_postcode
    with_http_stubs "npemap" do
      get :search_uk_postcode, :xhr => true,
                               :params => { :query => "CV4 7AL", :zoom => 10,
                                            :minlon => -0.559, :minlat => 51.217,
                                            :maxlon => 0.836, :maxlat => 51.766 }
      results_check :name => "CV4 7AL", :lat => 52.381748701968, :lon => -1.56176420939232

      get :search_uk_postcode, :xhr => true,
                               :params => { :query => "XX9 9XX", :zoom => 10,
                                            :minlon => -0.559, :minlat => 51.217,
                                            :maxlon => 0.836, :maxlat => 51.766 }
      results_check
    end
  end

  ##
  # Test the Canadian postcode search
  def test_search_ca_postcode
    with_http_stubs "geocoder_ca" do
      get :search_ca_postcode, :xhr => true,
                               :params => { :query => "A1B 2C3", :zoom => 10,
                                            :minlon => -0.559, :minlat => 51.217,
                                            :maxlon => 0.836, :maxlat => 51.766 }
      results_check :name => "A1B 2C3", :lat => "47.172520", :lon => "-55.440515"

      get :search_ca_postcode, :xhr => true,
                               :params => { :query => "k1a 0b1", :zoom => 10,
                                            :minlon => -0.559, :minlat => 51.217,
                                            :maxlon => 0.836, :maxlat => 51.766 }
      results_check :name => "K1A 0B1", :lat => "45.375437", :lon => "-75.691041"

      get :search_ca_postcode, :xhr => true,
                               :params => { :query => "Q0Q 0Q0", :zoom => 10,
                                            :minlon => -0.559, :minlat => 51.217,
                                            :maxlon => 0.836, :maxlat => 51.766 }
      results_check
    end
  end

  ##
  # Test the nominatim forward search
  def test_search_osm_nominatim
    with_http_stubs "nominatim" do
      get :search_osm_nominatim, :xhr => true,
                                 :params => { :query => "Hoddesdon", :zoom => 10,
                                              :minlon => -0.559, :minlat => 51.217,
                                              :maxlon => 0.836, :maxlat => 51.766 }
      results_check "name" => "Hoddesdon, Hertfordshire, East of England, England, United Kingdom",
                    "min-lat" => 51.7216709, "max-lat" => 51.8016709,
                    "min-lon" => -0.0512898, "max-lon" => 0.0287102,
                    "type" => "node", "id" => 18007599

      get :search_osm_nominatim, :xhr => true,
                                 :params => { :query => "Broxbourne", :zoom => 10,
                                              :minlon => -0.559, :minlat => 51.217,
                                              :maxlon => 0.836, :maxlat => 51.766 }
      results_check({ "prefix" => "Suburb",
                      "name" => "Broxbourne, Hertfordshire, East of England, England, United Kingdom",
                      "min-lat" => 51.7265723, "max-lat" => 51.7665723,
                      "min-lon" => -0.0390782, "max-lon" => 0.0009218,
                      "type" => "node", "id" => 28825933 },
                    { "prefix" => "Village",
                      "name" => "Broxbourne, Hertfordshire, East of England, England, United Kingdom",
                      "min-lat" => 51.6808751, "max-lat" => 51.7806237,
                      "min-lon" => -0.114204, "max-lon" => 0.0145267,
                      "type" => "relation", "id" => 2677978 },
                    { "prefix" => "Railway Station",
                      "name" => "Broxbourne, Stafford Drive, Broxbourne, Hertfordshire, East of England, England, United Kingdom",
                      "min-lat" => 51.7418469, "max-lat" => 51.7518469,
                      "min-lon" => -0.0156773, "max-lon" => -0.0056773,
                      "type" => "node", "id" => 17044599 })
    end
  end

  ##
  # Test the geonames forward search
  def test_search_geonames
    with_http_stubs "geonames" do
      get :search_geonames, :xhr => true,
                            :params => { :query => "Hoddesdon", :zoom => 10,
                                         :minlon => -0.559, :minlat => 51.217,
                                         :maxlon => 0.836, :maxlat => 51.766 }
      results_check :name => "Hoddesdon", :lat => 51.76148, :lon => -0.01144

      get :search_geonames, :xhr => true,
                            :params => { :query => "Broxbourne", :zoom => 10,
                                         :minlon => -0.559, :minlat => 51.217,
                                         :maxlon => 0.836, :maxlat => 51.766 }
      results_check({ :name => "Broxbourne", :lat => 51.74712, :lon => -0.01923 },
                    { :name => "Broxbourne District", :lat => 51.73026, :lon => -0.04821 },
                    { :name => "Cheshunt", :lat => 51.70791, :lon => -0.03739 },
                    { :name => "Hoddesdon", :lat => 51.76148, :lon => -0.01144 },
                    { :name => "Waltham Cross", :lat => 51.68905, :lon => -0.0333 },
                    { :name => "Goffs Oak", :lat => 51.71015, :lon => -0.0872 },
                    { :name => "Wormley", :lat => 51.7324, :lon => -0.0242 },
                    { :name => "Broxbourne", :lat => -27.50314, :lon => 151.378 },
                    { :name => "Lee Valley White Water Centre", :lat => 51.68814, :lon => -0.01682 },
                    { :name => "Cheshunt Railway Station", :lat => 51.703, :lon => -0.024 },
                    { :name => "Theobalds Grove Railway Station", :lat => 51.692, :lon => -0.035 },
                    { :name => "Waltham Cross Railway Station", :lat => 51.685, :lon => -0.027 },
                    { :name => "Rye House Station", :lat => 51.76938, :lon => 0.00562 },
                    { :name => "Broxbourne Station", :lat => 51.74697, :lon => -0.01105 },
                    { :name => "Broxbornebury Park", :lat => 51.75252, :lon => -0.03839 },
                    { :name => "Marriott Cheshunt", :lat => 51.7208, :lon => -0.0324 },
                    { :name => "Cheshunt Community Hospital", :lat => 51.68396, :lon => -0.03951 })
    end
  end

  ##
  # Test the nominatim reverse search
  def test_search_osm_nominatim_reverse
    with_http_stubs "nominatim" do
      get :search_osm_nominatim_reverse, :xhr => true,
                                         :params => { :lat => 51.7632, :lon => -0.0076, :zoom => 15 }
      results_check :name => "Broxbourne, Hertfordshire, East of England, England, United Kingdom",
                    :lat => 51.7465723, :lon => -0.0190782,
                    :type => "node", :id => 28825933, :zoom => 15

      get :search_osm_nominatim_reverse, :xhr => true,
                                         :params => { :lat => 51.7632, :lon => -0.0076, :zoom => 17 }
      results_check :name => "Dinant Link Road, Broxbourne, Hertfordshire, East of England, England, EN11 8HX, United Kingdom",
                    :lat => 51.7634883, :lon => -0.0088373,
                    :type => "way", :id => 3489841, :zoom => 17
    end
  end

  ##
  # Test the geonames reverse search
  def test_search_geonames_reverse
    with_http_stubs "geonames" do
      get :search_geonames_reverse, :xhr => true,
                                    :params => { :lat => 51.7632, :lon => -0.0076, :zoom => 15 }
      results_check :name => "England", :suffix => ", United Kingdom",
                    :lat => 51.7632, :lon => -0.0076
    end
  end

  private

  def latlon_check(query, lat, lon)
    get :search, :params => { :query => query }
    assert_response :success
    assert_template :search
    assert_template :layout => "map"
    assert_equal %w[latlon osm_nominatim_reverse geonames_reverse], assigns(:sources)
    assert_nil @controller.params[:query]
    assert_in_delta lat, @controller.params[:lat]
    assert_in_delta lon, @controller.params[:lon]

    get :search, :params => { :query => query }, :xhr => true
    assert_response :success
    assert_template :search
    assert_template :layout => "xhr"
    assert_equal %w[latlon osm_nominatim_reverse geonames_reverse], assigns(:sources)
    assert_nil @controller.params[:query]
    assert_in_delta lat, @controller.params[:lat]
    assert_in_delta lon, @controller.params[:lon]
  end

  def search_check(query, sources)
    get :search, :params => { :query => query }
    assert_response :success
    assert_template :search
    assert_template :layout => "map"
    assert_equal sources, assigns(:sources)

    get :search, :params => { :query => query }, :xhr => true
    assert_response :success
    assert_template :search
    assert_template :layout => "xhr"
    assert_equal sources, assigns(:sources)
  end

  def results_check(*results)
    assert_response :success
    assert_template :results
    assert_template :layout => nil
    if results.empty?
      assert_select "ul.results-list", 0
    else
      assert_select "ul.results-list", 1 do
        assert_select "p.search_results_entry", results.count

        results.each do |result|
          attrs = result.collect { |k, v| "[data-#{k}='#{v}']" }.join("")
          assert_select "p.search_results_entry a.set_position#{attrs}", result[:name]
        end
      end
    end
  end

  def results_check_error(error)
    assert_response :success
    assert_template :error
    assert_template :layout => nil
    assert_select "p.search_results_error", error
  end
end
