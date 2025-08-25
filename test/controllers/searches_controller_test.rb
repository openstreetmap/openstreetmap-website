# frozen_string_literal: true

require "test_helper"

class SearchesControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/search", :method => :get },
      { :controller => "searches", :action => "show" }
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
      "50.06773/14.37742",
      "50.06773, 14.37742",
      "+50.06773 +14.37742",
      "+50.06773, +14.37742",
      "+50.06773/+14.37742"
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
  # Test identification of integer lat/lon pairs using N/E with degrees
  def test_identify_latlon_ne_d_int_deg
    [
      "N50 E14",
      "N50° E14°",
      "50N 14E",
      "50°N 14°E"
    ].each do |code|
      latlon_check code, 50, 14
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
  # Test identification of lat/lon pairs with missing fractions
  def test_no_identify_latlon_ne_missing_fraction_part
    [
      "N50. E14.",
      "N50.° E14.°",
      "50.N 14.E",
      "50.°N 14.°E",
      "N50 1.' E14 2.'",
      "N50° 1.' E14° 2.'",
      "50N 1.' 14 2.'E",
      "50° 1.'N 14° 2.'E",
      "N50 1' 3,\" E14 2' 4.\"",
      "N50° 1' 3.\" E14° 2' 4.\"",
      "50N 1' 3.\" 14 2' 4.\"E",
      "50° 1' 3.\"N 14° 2' 4.\"E"
    ].each do |code|
      get search_path(:query => code)
      assert_response :success
      assert_template :show
      assert_template :layout => "map"
      assert_equal %w[nominatim], assigns(:sources).pluck(:name)
    end
  end

  #
  # Test identification of lat/lon pairs with mixed precision
  def test_identify_latlon_ne_mixed_precision
    latlon_check "N1 5 E15",    1.083333, 15
    latlon_check "N1 5 9 E15",  1.085833, 15
    latlon_check "N1 5 9 E1 5", 1.085833, 1.083333
    latlon_check "N15 E1 5",    15, 1.083333
    latlon_check "N15 E1 5 9",  15, 1.085833
    latlon_check "N1 5 E1 5 9", 1.083333, 1.085833
  end

  #
  # Test identification of lat/lon pairs with values close to zero
  def test_identify_latlon_close_to_zero
    [
      "0.0000123 -0.0000456",
      "+0.0000123 -0.0000456",
      "N 0° 0' 0.4428\", W 0° 0' 1.6416\""
    ].each do |code|
      latlon_check code, 0.0000123, -0.0000456
    end
  end

  ##
  # Test identification of US zipcodes
  def test_identify_us_postcode
    %w[
      12345
      12345-6789
    ].each do |code|
      search_check code, %w[nominatim]
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
      search_check code, %w[nominatim]
    end
  end

  ##
  # Test identification of Canadian postcodes
  def test_identify_ca_postcode
    search_check "A1B 2C3", %w[nominatim]
  end

  ##
  # Test identification fall through to the default case
  def test_identify_default
    search_check "foo bar baz", %w[nominatim]
  end

  ##
  # Test the nominatim reverse JSON search
  def test_search_osm_nominatim_reverse_json
    with_http_stubs "nominatim" do
      post search_nominatim_reverse_query_path(:lat => 51.7632, :lon => -0.0076, :zoom => 15, :format => "json"), :xhr => true
      result_name_check_json("Broxbourne, Hertfordshire, East of England, England, United Kingdom")

      post search_nominatim_reverse_query_path(:lat => 51.7632, :lon => -0.0076, :zoom => 17, :format => "json"), :xhr => true
      result_name_check_json("Dinant Link Road, Broxbourne, Hertfordshire, East of England, England, EN11 8HX, United Kingdom")

      post search_nominatim_reverse_query_path(:lat => 13.7709, :lon => 100.50507, :zoom => 19, :format => "json"), :xhr => true
      result_name_check_json("MM Steak&Grill, ถนนศรีอยุธยา, บางขุนพรหม, กรุงเทพมหานคร, เขตดุสิต, กรุงเทพมหานคร, 10300, ประเทศไทย")
    end
  end

  private

  def latlon_check(query, lat, lon)
    get search_path(:query => query)
    assert_response :success
    assert_template :show
    assert_template :layout => "map"
    assert_equal %w[latlon nominatim_reverse], assigns(:sources).pluck(:name)
    assert_nil @controller.params[:query]
    assert_match(/^[+-]?\d+(?:\.\d+)?$/, @controller.params[:lat])
    assert_match(/^[+-]?\d+(?:\.\d+)?$/, @controller.params[:lon])
    assert_in_delta lat, @controller.params[:lat].to_f
    assert_in_delta lon, @controller.params[:lon].to_f

    get search_path(:query => query), :xhr => true
    assert_response :success
    assert_template :show
    assert_template :layout => "xhr"
    assert_equal %w[latlon nominatim_reverse], assigns(:sources).pluck(:name)
    assert_nil @controller.params[:query]
    assert_match(/^[+-]?\d+(?:\.\d+)?$/, @controller.params[:lat])
    assert_match(/^[+-]?\d+(?:\.\d+)?$/, @controller.params[:lon])
    assert_in_delta lat, @controller.params[:lat].to_f
    assert_in_delta lon, @controller.params[:lon].to_f
  end

  def search_check(query, sources)
    get search_path(:query => query)
    assert_response :success
    assert_template :show
    assert_template :layout => "map"
    assert_equal sources, assigns(:sources).pluck(:name)

    get search_path(:query => query), :xhr => true
    assert_response :success
    assert_template :show
    assert_template :layout => "xhr"
    assert_equal sources, assigns(:sources).pluck(:name)
  end

  def result_name_check_json(name)
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal name, js[0]["name"]
  end
end
