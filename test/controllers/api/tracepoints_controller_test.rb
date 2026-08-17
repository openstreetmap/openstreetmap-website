# frozen_string_literal: true

require "test_helper"

module Api
  class TracepointsControllerTest < ActionDispatch::IntegrationTest
    def setup
      super
      @badbigbbox = %w[-0.1,-0.1,1.1,1.1 10,10,11,11]
      @badmalformedbbox = %w[-0.1 hello
                             10N2W10.1N2.1W]
      @badlatmixedbbox = %w[0,0.1,0.1,0 -0.1,80,0.1,70 0.24,54.34,0.25,54.33]
      @badlonmixedbbox = %w[80,-0.1,70,0.1 54.34,0.24,54.33,0.25]
      # @badlatlonoutboundsbbox = %w{ 191,-0.1,193,0.1  -190.1,89.9,-190,90 }
      @goodbbox = %w[-0.1,-0.1,0.1,0.1 51.1,-0.1,51.2,0
                     -0.1,%20-0.1,%200.1,%200.1 -0.1edcd,-0.1d,0.1,0.1 -0.1E,-0.1E,0.1S,0.1N S0.1,W0.1,N0.1,E0.1]
      # That last item in the goodbbox really shouldn't be there, as the API should
      # really reject it, however this is to test to see if the api changes.
    end

    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/trackpoints", :method => :get },
        { :controller => "api/tracepoints", :action => "index" }
      )
    end

    def test_tracepoints_public_not_served
      point = create(:trace, :without_validations, :visibility => "public", :latitude => 1, :longitude => 1) do |trace|
        create(:tracepoint, :trace => trace, :latitude => 1 * GeoRecord::SCALE, :longitude => 1 * GeoRecord::SCALE)
      end
      minlon = point.longitude - 0.001
      minlat = point.latitude - 0.001
      maxlon = point.longitude + 0.001
      maxlat = point.latitude + 0.001
      bbox = "#{minlon},#{minlat},#{maxlon},#{maxlat}"
      get api_tracepoints_path(:bbox => bbox)
      assert_response :success
      assert_select "gpx[version='1.0'][creator='OpenStreetMap.org']", :count => 1 do
        assert_select "trk", :count => 0
      end
    end

    def test_tracepoints_private_not_served
      point = create(:trace, :without_validations, :visibility => "private", :latitude => 1, :longitude => 1) do |trace|
        create(:tracepoint, :trace => trace, :latitude => 1 * GeoRecord::SCALE, :longitude => 1 * GeoRecord::SCALE)
      end
      minlon = point.longitude - 0.001
      minlat = point.latitude - 0.001
      maxlon = point.longitude + 0.001
      maxlat = point.latitude + 0.001
      bbox = "#{minlon},#{minlat},#{maxlon},#{maxlat}"
      get api_tracepoints_path(:bbox => bbox)
      assert_response :success
      assert_select "gpx[version='1.0'][creator='OpenStreetMap.org']", :count => 1 do
        assert_select "trk", :count => 0
      end
    end

    def test_tracepoints_trackable
      point = create(:trace, :visibility => "trackable", :latitude => 51.51, :longitude => -0.14) do |trace|
        create(:tracepoint, :trace => trace, :trackid => 1, :latitude => (51.510 * GeoRecord::SCALE).to_i, :longitude => (-0.140 * GeoRecord::SCALE).to_i)
        create(:tracepoint, :trace => trace, :trackid => 2, :latitude => (51.511 * GeoRecord::SCALE).to_i, :longitude => (-0.141 * GeoRecord::SCALE).to_i)
      end
      minlon = point.longitude - 0.002
      minlat = point.latitude - 0.002
      maxlon = point.longitude + 0.002
      maxlat = point.latitude + 0.002
      bbox = "#{minlon},#{minlat},#{maxlon},#{maxlat}"
      get api_tracepoints_path(:bbox => bbox)
      assert_response :success
      assert_select "gpx[version='1.0'][creator='OpenStreetMap.org']", :count => 1 do
        assert_select "trk", :count => 1 do
          assert_select "name", :count => 0
          assert_select "desc", :count => 0
          assert_select "url", :count => 0
          assert_select "trkseg", :count => 2 do |trksegs|
            trksegs.each do |trkseg|
              assert_select trkseg, "trkpt", :count => 1 do |trkpt|
                assert_select trkpt[0], "time", :count => 1
              end
            end
          end
        end
      end
    end

    def test_tracepoints_identifiable
      point = create(:trace, :visibility => "identifiable", :latitude => 51.512, :longitude => 0.142) do |trace|
        create(:tracepoint, :trace => trace, :latitude => (51.512 * GeoRecord::SCALE).to_i, :longitude => (0.142 * GeoRecord::SCALE).to_i)
      end
      minlon = point.longitude - 0.002
      minlat = point.latitude - 0.002
      maxlon = point.longitude + 0.002
      maxlat = point.latitude + 0.002
      bbox = "#{minlon},#{minlat},#{maxlon},#{maxlat}"
      get api_tracepoints_path(:bbox => bbox)
      assert_response :success
      assert_select "gpx[version='1.0'][creator='OpenStreetMap.org']", :count => 1 do
        assert_select "trk", :count => 1 do
          assert_select "name", :count => 1
          assert_select "desc", :count => 1
          assert_select "url", :count => 1
          assert_select "trkseg", :count => 1 do
            assert_select "trkpt", :count => 1 do
              assert_select "time", :count => 1
            end
          end
        end
      end
    end

    def test_tracepoints_cursor_pagination
      create(:trace, :visibility => "trackable") do |trace|
        create(:tracepoint, :trace => trace, :timestamp => Time.utc(2026, 1, 1, 0, 0, 0))
        create(:tracepoint, :trace => trace, :timestamp => Time.utc(2026, 1, 1, 0, 0, 1))
        create(:tracepoint, :trace => trace, :timestamp => Time.utc(2026, 1, 1, 0, 0, 2))
        create(:tracepoint, :trace => trace, :timestamp => Time.utc(2026, 1, 1, 0, 0, 3))
      end

      with_settings(:tracepoints_per_page => 3) do
        get api_tracepoints_path(:bbox => "0.9,0.9,1.1,1.1")
        assert_response :success
        assert_select "trkpt", :count => 3
        next_url = @response.headers["Link"][/<(.*)>; rel="next"/, 1]
        assert_not_nil next_url

        get next_url
        assert_response :success
        assert_select "trkpt", :count => 1
        assert_nil @response.headers["Link"]
      end
    end

    def test_tracepoints_cursor_pagination_across_traces
      create(:trace, :visibility => "trackable") do |trace|
        create(:tracepoint, :trace => trace, :timestamp => Time.utc(2026, 1, 1, 0, 0, 0))
        create(:tracepoint, :trace => trace, :timestamp => Time.utc(2026, 1, 1, 0, 0, 1))
      end
      create(:trace, :visibility => "trackable") do |trace|
        create(:tracepoint, :trace => trace, :latitude => (1.05 * GeoRecord::SCALE).to_i, :timestamp => Time.utc(2026, 1, 2, 0, 0, 0))
        create(:tracepoint, :trace => trace, :latitude => (1.05 * GeoRecord::SCALE).to_i, :timestamp => Time.utc(2026, 1, 2, 0, 0, 1))
      end

      with_settings(:tracepoints_per_page => 2) do
        # the first page has all the points of the newest trace
        get api_tracepoints_path(:bbox => "0.9,0.9,1.1,1.1")
        assert_response :success
        assert_select "trkpt", :count => 2
        assert_match(/lat="1.0500000"/, response.body)
        assert_no_match(/lat="1.0000000"/, response.body)

        # the second page continues with the older trace
        next_url = @response.headers["Link"][/<(.*)>; rel="next"/, 1]
        get next_url
        assert_response :success
        assert_select "trkpt", :count => 2
        assert_match(/lat="1.0000000"/, response.body)
        assert_no_match(/lat="1.0500000"/, response.body)

        # following the link once more returns an empty document
        next_url = @response.headers["Link"][/<(.*)>; rel="next"/, 1]
        get next_url
        assert_response :success
        assert_select "trkpt", :count => 0
        assert_nil @response.headers["Link"]
      end
    end

    def test_tracepoints_cursor_pagination_across_track_segments
      create(:trace, :visibility => "trackable") do |trace|
        create(:tracepoint, :trace => trace, :trackid => 1, :timestamp => Time.utc(2026, 1, 1, 0, 0, 0))
        create(:tracepoint, :trace => trace, :trackid => 1, :timestamp => Time.utc(2026, 1, 1, 0, 0, 1))
        create(:tracepoint, :trace => trace, :trackid => 2, :timestamp => Time.utc(2026, 1, 1, 0, 0, 2))
        create(:tracepoint, :trace => trace, :trackid => 2, :timestamp => Time.utc(2026, 1, 1, 0, 0, 3))
      end

      with_settings(:tracepoints_per_page => 2) do
        # the first page has the two points of the first track segment
        get api_tracepoints_path(:bbox => "0.9,0.9,1.1,1.1")
        assert_response :success
        assert_select "trkseg", :count => 1
        assert_select "trkpt", :count => 2

        # the second page has the two points of the second track segment
        next_url = @response.headers["Link"][/<(.*)>; rel="next"/, 1]
        get next_url
        assert_response :success
        assert_select "trkseg", :count => 1
        assert_select "trkpt", :count => 2
      end
    end

    def test_tracepoints_paged_mode_has_no_link_header
      create(:trace, :visibility => "trackable") do |trace|
        create(:tracepoint, :trace => trace)
      end

      with_settings(:tracepoints_per_page => 1) do
        get api_tracepoints_path(:page => 0, :bbox => "0.9,0.9,1.1,1.1")
        assert_response :success
        assert_select "trkpt", :count => 1
        assert_nil @response.headers["Link"]
      end
    end

    def test_tracepoints_invalid_cursor
      get api_tracepoints_path(:bbox => "-0.1,-0.1,0.1,0.1", :cursor => "not a cursor")
      assert_response :bad_request
      assert_equal "The cursor parameter is invalid", @response.body
    end

    def test_tracepoints_cursor_with_invalid_values
      get api_tracepoints_path(:bbox => "-0.1,-0.1,0.1,0.1", :cursor => Base64.urlsafe_encode64("hello"))
      assert_response :bad_request
      assert_equal "The cursor parameter is invalid", @response.body

      get api_tracepoints_path(:bbox => "-0.1,-0.1,0.1,0.1", :cursor => Base64.urlsafe_encode64("1|2|not a time"))
      assert_response :bad_request
      assert_equal "The cursor parameter is invalid", @response.body
    end

    def test_tracepoints_disabled
      with_settings(:traces_disabled => true) do
        get api_tracepoints_path(:bbox => "-0.1,-0.1,0.1,0.1")
        assert_response :not_found
      end
    end

    def test_index_without_bbox
      get api_tracepoints_path
      assert_response :bad_request
      assert_equal "The parameter bbox is required", @response.body, "A bbox param was expected"
    end

    def test_traces_page_less_than_zero
      -10.upto(-1) do |i|
        get api_tracepoints_path(:page => i, :bbox => "-0.1,-0.1,0.1,0.1")
        assert_response :bad_request
        assert_equal "Page number must be greater than or equal to 0", @response.body, "The page number was #{i}"
      end
      0.upto(10) do |i|
        get api_tracepoints_path(:page => i, :bbox => "-0.1,-0.1,0.1,0.1")
        assert_response :success, "The page number was #{i} and should have been accepted"
      end
    end

    def test_bbox_too_big
      @badbigbbox.each do |bbox|
        get api_tracepoints_path(:bbox => bbox)
        assert_response :bad_request, "The bbox:#{bbox} was expected to be too big"
        assert_equal "The maximum bbox size is #{Settings.max_request_area}, and your request was too large. Either request a smaller area, or use planet.osm", @response.body, "bbox: #{bbox}"
      end
    end

    def test_bbox_malformed
      @badmalformedbbox.each do |bbox|
        get api_tracepoints_path(:bbox => bbox)
        assert_response :bad_request, "The bbox:#{bbox} was expected to be malformed"
        assert_equal "The parameter bbox must be of the form min_lon,min_lat,max_lon,max_lat", @response.body, "bbox: #{bbox}"
      end
    end

    def test_bbox_lon_mixedup
      @badlonmixedbbox.each do |bbox|
        get api_tracepoints_path(:bbox => bbox)
        assert_response :bad_request, "The bbox:#{bbox} was expected to have the longitude mixed up"
        assert_equal "The minimum longitude must be less than the maximum longitude, but it wasn't", @response.body, "bbox: #{bbox}"
      end
    end

    def test_bbox_lat_mixedup
      @badlatmixedbbox.each do |bbox|
        get api_tracepoints_path(:bbox => bbox)
        assert_response :bad_request, "The bbox:#{bbox} was expected to have the latitude mixed up"
        assert_equal "The minimum latitude must be less than the maximum latitude, but it wasn't", @response.body, "bbox: #{bbox}"
      end
    end

    # Ensure the lat/lon is formatted as a decimal e.g. not 4.0e-05
    def test_lat_lon_xml_format
      create(:tracepoint, :latitude => (0.00004 * GeoRecord::SCALE).to_i, :longitude => (0.00008 * GeoRecord::SCALE).to_i)

      get api_tracepoints_path(:bbox => "0,0,0.1,0.1")
      assert_match(/lat="0.0000400"/, response.body)
      assert_match(/lon="0.0000800"/, response.body)
    end
  end
end
