require "test_helper"

class GeocoderControllerTest < ActionDispatch::IntegrationTest
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
      { :path => "/geocoder/search_osm_nominatim", :method => :get },
      { :controller => "geocoder", :action => "search_osm_nominatim" }
    )
    assert_routing(
      { :path => "/geocoder/search_osm_nominatim_reverse", :method => :get },
      { :controller => "geocoder", :action => "search_osm_nominatim_reverse" }
    )
  end

  ##
  # Test identification with no arguments
  def test_identify_error
    get search_path
    assert_response :bad_request

    get search_path, :xhr => true
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
    %w[
      12345
      12345-6789
    ].each do |code|
      search_check code, %w[osm_nominatim]
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
      search_check code, %w[osm_nominatim]
    end
  end

  ##
  # Test identification of Canadian postcodes
  def test_identify_ca_postcode
    search_check "A1B 2C3", %w[osm_nominatim]
  end

  ##
  # Test identification fall through to the default case
  def test_identify_default
    search_check "foo bar baz", %w[osm_nominatim]
  end

  ##
  # Test the builtin latitude+longitude search
  def test_search_latlon
    get geocoder_search_latlon_path(:lat => 1.23, :lon => 4.56, :zoom => 16), :xhr => true
    results_check :name => "1.23, 4.56", :lat => 1.23, :lon => 4.56, :zoom => 16

    get geocoder_search_latlon_path(:lat => -91.23, :lon => 4.56, :zoom => 16), :xhr => true
    results_check_error "Latitude -91.23 out of range"

    get geocoder_search_latlon_path(:lat => 91.23, :lon => 4.56, :zoom => 16), :xhr => true
    results_check_error "Latitude 91.23 out of range"

    get geocoder_search_latlon_path(:lat => 1.23, :lon => -180.23, :zoom => 16), :xhr => true
    results_check_error "Longitude -180.23 out of range"

    get geocoder_search_latlon_path(:lat => 1.23, :lon => 180.23, :zoom => 16), :xhr => true
    results_check_error "Longitude 180.23 out of range"
  end

  def test_search_latlon_digits
    get geocoder_search_latlon_path(:lat => 1.23, :lon => 4.56, :zoom => 16, :latlon_digits => true), :xhr => true
    results_check({ :name => "1.23, 4.56", :lat => 1.23, :lon => 4.56, :zoom => 16 },
                  { :name => "4.56, 1.23", :lat => 4.56, :lon => 1.23, :zoom => 16 })

    get geocoder_search_latlon_path(:lat => -91.23, :lon => 4.56, :zoom => 16, :latlon_digits => true), :xhr => true
    results_check :name => "4.56, -91.23", :lat => 4.56, :lon => -91.23, :zoom => 16

    get geocoder_search_latlon_path(:lat => -1.23, :lon => 170.23, :zoom => 16, :latlon_digits => true), :xhr => true
    results_check :name => "-1.23, 170.23", :lat => -1.23, :lon => 170.23, :zoom => 16

    get geocoder_search_latlon_path(:lat => 91.23, :lon => 94.56, :zoom => 16, :latlon_digits => true), :xhr => true
    results_check_error "Latitude or longitude are out of range"

    get geocoder_search_latlon_path(:lat => -91.23, :lon => -94.56, :zoom => 16, :latlon_digits => true), :xhr => true
    results_check_error "Latitude or longitude are out of range"

    get geocoder_search_latlon_path(:lat => 1.23, :lon => -180.23, :zoom => 16, :latlon_digits => true), :xhr => true
    results_check_error "Latitude or longitude are out of range"

    get geocoder_search_latlon_path(:lat => 1.23, :lon => 180.23, :zoom => 16, :latlon_digits => true), :xhr => true
    results_check_error "Latitude or longitude are out of range"
  end

  ##
  # Test the nominatim forward search
  def test_search_osm_nominatim
    with_http_stubs "nominatim" do
      get geocoder_search_osm_nominatim_path(:query => "Hoddesdon", :zoom => 10,
                                             :minlon => -0.559, :minlat => 51.217,
                                             :maxlon => 0.836, :maxlat => 51.766), :xhr => true
      results_check "name" => "Hoddesdon, Hertfordshire, East of England, England, United Kingdom",
                    "min-lat" => 51.7216709, "max-lat" => 51.8016709,
                    "min-lon" => -0.0512898, "max-lon" => 0.0287102,
                    "type" => "node", "id" => 18007599

      get geocoder_search_osm_nominatim_path(:query => "Broxbourne", :zoom => 10,
                                             :minlon => -0.559, :minlat => 51.217,
                                             :maxlon => 0.836, :maxlat => 51.766), :xhr => true
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
  # Test the nominatim reverse search
  def test_search_osm_nominatim_reverse
    with_http_stubs "nominatim" do
      get geocoder_search_osm_nominatim_reverse_path(:lat => 51.7632, :lon => -0.0076, :zoom => 15), :xhr => true
      results_check :name => "Broxbourne, Hertfordshire, East of England, England, United Kingdom",
                    :lat => 51.7465723, :lon => -0.0190782,
                    :type => "node", :id => 28825933, :zoom => 15

      get geocoder_search_osm_nominatim_reverse_path(:lat => 51.7632, :lon => -0.0076, :zoom => 17), :xhr => true
      results_check :name => "Dinant Link Road, Broxbourne, Hertfordshire, East of England, England, EN11 8HX, United Kingdom",
                    :lat => 51.7634883, :lon => -0.0088373,
                    :type => "way", :id => 3489841, :zoom => 17

      get geocoder_search_osm_nominatim_reverse_path(:lat => 13.7709, :lon => 100.50507, :zoom => 19), :xhr => true
      results_check :name => "MM Steak&Grill, ถนนศรีอยุธยา, บางขุนพรหม, กรุงเทพมหานคร, เขตดุสิต, กรุงเทพมหานคร, 10300, ประเทศไทย",
                    :lat => 13.7708691, :lon => 100.505073233221,
                    :type => "way", :id => 542901374, :zoom => 19
    end
  end

  private

  def latlon_check(query, lat, lon)
    get search_path(:query => query)
    assert_response :success
    assert_template :search
    assert_template :layout => "map"
    assert_equal %w[latlon osm_nominatim_reverse], assigns(:sources)
    assert_nil @controller.params[:query]
    assert_in_delta lat, @controller.params[:lat]
    assert_in_delta lon, @controller.params[:lon]

    get search_path(:query => query), :xhr => true
    assert_response :success
    assert_template :search
    assert_template :layout => "xhr"
    assert_equal %w[latlon osm_nominatim_reverse], assigns(:sources)
    assert_nil @controller.params[:query]
    assert_in_delta lat, @controller.params[:lat]
    assert_in_delta lon, @controller.params[:lon]
  end

  def search_check(query, sources)
    get search_path(:query => query)
    assert_response :success
    assert_template :search
    assert_template :layout => "map"
    assert_equal sources, assigns(:sources)

    get search_path(:query => query), :xhr => true
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
        assert_select "li.search_results_entry", results.count

        results.each do |result|
          attrs = result.collect { |k, v| "[data-#{k}='#{v}']" }.join
          assert_select "li.search_results_entry a.set_position#{attrs}", result[:name]
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
