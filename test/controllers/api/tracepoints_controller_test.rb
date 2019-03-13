require "test_helper"

module Api
  class TracepointsControllerTest < ActionController::TestCase
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
      # reall reject it, however this is to test to see if the api changes.
    end

    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/trackpoints", :method => :get },
        { :controller => "api/tracepoints", :action => "index" }
      )
    end

    def test_tracepoints
      point = create(:trace, :visibility => "public", :latitude => 1, :longitude => 1) do |trace|
        create(:tracepoint, :trace => trace, :latitude => 1 * GeoRecord::SCALE, :longitude => 1 * GeoRecord::SCALE)
      end
      minlon = point.longitude - 0.001
      minlat = point.latitude - 0.001
      maxlon = point.longitude + 0.001
      maxlat = point.latitude + 0.001
      bbox = "#{minlon},#{minlat},#{maxlon},#{maxlat}"
      get :index, :params => { :bbox => bbox }
      assert_response :success
      assert_select "gpx[version='1.0'][creator='OpenStreetMap.org']", :count => 1 do
        assert_select "trk" do
          assert_select "trkseg"
        end
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
      get :index, :params => { :bbox => bbox }
      assert_response :success
      assert_select "gpx[version='1.0'][creator='OpenStreetMap.org']", :count => 1 do
        assert_select "trk", :count => 1 do
          assert_select "trk > trkseg", :count => 2 do |trksegs|
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
      get :index, :params => { :bbox => bbox }
      assert_response :success
      assert_select "gpx[version='1.0'][creator='OpenStreetMap.org']", :count => 1 do
        assert_select "trk", :count => 1 do
          assert_select "trk>name", :count => 1
          assert_select "trk>desc", :count => 1
          assert_select "trk>url", :count => 1
          assert_select "trkseg", :count => 1 do
            assert_select "trkpt", :count => 1 do
              assert_select "time", :count => 1
            end
          end
        end
      end
    end

    def test_index_without_bbox
      get :index
      assert_response :bad_request
      assert_equal "The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat", @response.body, "A bbox param was expected"
    end

    def test_traces_page_less_than_0
      -10.upto(-1) do |i|
        get :index, :params => { :page => i, :bbox => "-0.1,-0.1,0.1,0.1" }
        assert_response :bad_request
        assert_equal "Page number must be greater than or equal to 0", @response.body, "The page number was #{i}"
      end
      0.upto(10) do |i|
        get :index, :params => { :page => i, :bbox => "-0.1,-0.1,0.1,0.1" }
        assert_response :success, "The page number was #{i} and should have been accepted"
      end
    end

    def test_bbox_too_big
      @badbigbbox.each do |bbox|
        get :index, :params => { :bbox => bbox }
        assert_response :bad_request, "The bbox:#{bbox} was expected to be too big"
        assert_equal "The maximum bbox size is #{Settings.max_request_area}, and your request was too large. Either request a smaller area, or use planet.osm", @response.body, "bbox: #{bbox}"
      end
    end

    def test_bbox_malformed
      @badmalformedbbox.each do |bbox|
        get :index, :params => { :bbox => bbox }
        assert_response :bad_request, "The bbox:#{bbox} was expected to be malformed"
        assert_equal "The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat", @response.body, "bbox: #{bbox}"
      end
    end

    def test_bbox_lon_mixedup
      @badlonmixedbbox.each do |bbox|
        get :index, :params => { :bbox => bbox }
        assert_response :bad_request, "The bbox:#{bbox} was expected to have the longitude mixed up"
        assert_equal "The minimum longitude must be less than the maximum longitude, but it wasn't", @response.body, "bbox: #{bbox}"
      end
    end

    def test_bbox_lat_mixedup
      @badlatmixedbbox.each do |bbox|
        get :index, :params => { :bbox => bbox }
        assert_response :bad_request, "The bbox:#{bbox} was expected to have the latitude mixed up"
        assert_equal "The minimum latitude must be less than the maximum latitude, but it wasn't", @response.body, "bbox: #{bbox}"
      end
    end
  end
end
