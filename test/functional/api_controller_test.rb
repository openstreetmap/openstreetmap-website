require File.dirname(__FILE__) + '/../test_helper'
require 'api_controller'

class ApiControllerTest < ActionController::TestCase
  api_fixtures
  
  def setup
    super
    @badbigbbox = %w{ -0.1,-0.1,1.1,1.1  10,10,11,11 }
    @badmalformedbbox = %w{ -0.1  hello 
    10N2W10.1N2.1W }
    @badlatmixedbbox = %w{ 0,0.1,0.1,0  -0.1,80,0.1,70  0.24,54.34,0.25,54.33 }
    @badlonmixedbbox = %w{ 80,-0.1,70,0.1  54.34,0.24,54.33,0.25 }  
    #@badlatlonoutboundsbbox = %w{ 191,-0.1,193,0.1  -190.1,89.9,-190,90 }
    @goodbbox = %w{ -0.1,-0.1,0.1,0.1  51.1,-0.1,51.2,0 
    -0.1,%20-0.1,%200.1,%200.1  -0.1edcd,-0.1d,0.1,0.1  -0.1E,-0.1E,0.1S,0.1N S0.1,W0.1,N0.1,E0.1}
    # That last item in the goodbbox really shouldn't be there, as the API should
    # reall reject it, however this is to test to see if the api changes.
  end

  def basic_authorization(user, pass)
    @request.env["HTTP_AUTHORIZATION"] = "Basic %s" % Base64.encode64("#{user}:#{pass}")
  end

  # -------------------------------------
  # Test reading a bounding box.
  # -------------------------------------

  def test_map
    node = current_nodes(:used_node_1)
    # Need to split the min/max lat/lon out into their own variables here
    # so that we can test they are returned later.
    minlon = node.lon-0.1
    minlat = node.lat-0.1
    maxlon = node.lon+0.1
    maxlat = node.lat+0.1
    bbox = "#{minlon},#{minlat},#{maxlon},#{maxlat}"
    get :map, :bbox => bbox
    if $VERBOSE
      print @request.to_yaml
      print @response.body
    end
    assert_response :success, "Expected scucess with the map call"
    assert_select "osm[version='#{API_VERSION}'][generator='#{GENERATOR}']:root", :count => 1 do
      assert_select "bounds[minlon=#{minlon}][minlat=#{minlat}][maxlon=#{maxlon}][maxlat=#{maxlat}]", :count => 1
      assert_select "node[id=#{node.id}][lat=#{node.lat}][lon=#{node.lon}][version=#{node.version}][changeset=#{node.changeset_id}][visible=#{node.visible}][timestamp=#{node.timestamp.xmlschema}]", :count => 1 do
        # This should really be more generic
        assert_select "tag[k='test'][v='yes']"
      end
      # Should also test for the ways and relation
    end
  end
  
  # This differs from the above test in that we are making the bbox exactly
  # the same as the node we are looking at
  def test_map_inclusive
    node = current_nodes(:used_node_1)
    bbox = "#{node.lon},#{node.lat},#{node.lon},#{node.lat}"
    get :map, :bbox => bbox
    #print @response.body
    assert_response :success, "The map call should have succeeded"
    assert_select "osm[version='#{API_VERSION}'][generator='#{GENERATOR}']:root:empty", :count => 1
  end
  
  def test_tracepoints
    point = gpx_files(:first_trace_file)
    minlon = point.longitude-0.1
    minlat = point.latitude-0.1
    maxlon = point.longitude+0.1
    maxlat = point.latitude+0.1
    bbox = "#{minlon},#{minlat},#{maxlon},#{maxlat}"
    get :trackpoints, :bbox => bbox
    #print @response.body
    assert_response :success
    assert_select "gpx[version=1.0][creator=OpenStreetMap.org][xmlns=http://www.topografix.com/GPX/1/0/]:root", :count => 1 do
      assert_select "trk" do
        assert_select "trkseg"
      end
    end
  end
  
  def test_map_without_bbox
    ["trackpoints", "map"].each do |tq|
      get tq
      assert_response :bad_request
      assert_equal "The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat", @response.body, "A bbox param was expected"
    end
  end
  
  def test_traces_page_less_than_0
    -10.upto(-1) do |i|
      get :trackpoints, :page => i, :bbox => "-0.1,-0.1,0.1,0.1"
      assert_response :bad_request
      assert_equal "Page number must be greater than or equal to 0", @response.body, "The page number was #{i}"
    end
    0.upto(10) do |i|
      get :trackpoints, :page => i, :bbox => "-0.1,-0.1,0.1,0.1"
      assert_response :success, "The page number was #{i} and should have been accepted"
    end
  end
  
  def test_bbox_too_big
    @badbigbbox.each do |bbox|
      [ "trackpoints", "map" ].each do |tq|
        get tq, :bbox => bbox
        assert_response :bad_request, "The bbox:#{bbox} was expected to be too big"
        assert_equal "The maximum bbox size is #{APP_CONFIG['max_request_area']}, and your request was too large. Either request a smaller area, or use planet.osm", @response.body, "bbox: #{bbox}"
      end
    end
  end
  
  def test_bbox_malformed
    @badmalformedbbox.each do |bbox|
      [ "trackpoints", "map" ].each do |tq|
        get tq, :bbox => bbox
        assert_response :bad_request, "The bbox:#{bbox} was expected to be malformed"
        assert_equal "The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat", @response.body, "bbox: #{bbox}"
      end
    end
  end
  
  def test_bbox_lon_mixedup
    @badlonmixedbbox.each do |bbox|
      [ "trackpoints", "map" ].each do |tq|
        get tq, :bbox => bbox
        assert_response :bad_request, "The bbox:#{bbox} was expected to have the longitude mixed up"
        assert_equal "The minimum longitude must be less than the maximum longitude, but it wasn't", @response.body, "bbox: #{bbox}"
      end
    end
  end
  
  def test_bbox_lat_mixedup
    @badlatmixedbbox.each do |bbox|
      ["trackpoints", "map"].each do |tq|
        get tq, :bbox => bbox
        assert_response :bad_request, "The bbox:#{bbox} was expected to have the latitude mixed up"
        assert_equal "The minimum latitude must be less than the maximum latitude, but it wasn't", @response.body, "bbox: #{bbox}"
      end
    end
  end
  
  # We can't actually get an out of bounds error, as the bbox is sanitised.
  #def test_latlon_outofbounds
  #  @badlatlonoutboundsbbox.each do |bbox|
  #    [ "trackpoints", "map" ].each do |tq|
  #      get tq, :bbox => bbox
  #      #print @request.to_yaml
  #      assert_response :bad_request, "The bbox #{bbox} was expected to be out of range"
  #      assert_equal "The latitudes must be between -90 an 90, and longitudes between -180 and 180", @response.body, "bbox: #{bbox}"
  #    end
  #  end
  #end
  
  # MySQL requires that the C based functions are installed for this test to 
  # work. More information is available from:
  # http://wiki.openstreetmap.org/index.php/Rails#Installing_the_quadtile_functions
  def test_changes_simple
    get :changes
    assert_response :success
    #print @response.body
    # As we have loaded the fixtures, we can assume that there are no 
    # changes recently
    now = Time.now.getutc
    hourago = now - 1.hour
    # Note that this may fail on a very slow machine, so isn't a great test
    assert_select "osm[version='#{API_VERSION}'][generator='#{GENERATOR}']:root", :count => 1 do
      assert_select "changes[starttime='#{hourago.xmlschema}'][endtime='#{now.xmlschema}']", :count => 1
    end
  end
  
  def test_changes_zoom_invalid
    zoom_to_test = %w{ p -1 0 17 one two }
    zoom_to_test.each do |zoom|
      get :changes, :zoom => zoom
      assert_response :bad_request
      assert_equal @response.body, "Requested zoom is invalid, or the supplied start is after the end time, or the start duration is more than 24 hours"
    end
  end
  
  def test_changes_zoom_valid
    1.upto(16) do |zoom|
      get :changes, :zoom => zoom
      assert_response :success
      now = Time.now.getutc
      hourago = now - 1.hour
      # Note that this may fail on a very slow machine, so isn't a great test
      assert_select "osm[version='#{API_VERSION}'][generator='#{GENERATOR}']:root", :count => 1 do
        assert_select "changes[starttime='#{hourago.xmlschema}'][endtime='#{now.xmlschema}']", :count => 1
      end
    end
  end
  
  def test_start_end_time_invalid
    
  end
  
  def test_start_end_time_invalid
    
  end
  
  def test_hours_invalid
    invalid = %w{ -21 335 -1 0 25 26 100 one two three ping pong : }
    invalid.each do |hour|
      get :changes, :hours => hour
      assert_response :bad_request, "Problem with the hour: #{hour}"
      assert_equal @response.body, "Requested zoom is invalid, or the supplied start is after the end time, or the start duration is more than 24 hours", "Problem with the hour: #{hour}."
    end
  end
  
  def test_hours_valid
    1.upto(24) do |hour|
      get :changes, :hours => hour
      assert_response :success
    end
  end
  
  def test_capabilities
    get :capabilities
    assert_response :success
    assert_select "osm:root[version='#{API_VERSION}'][generator='#{GENERATOR}']", :count => 1 do
      assert_select "api", :count => 1 do
        assert_select "version[minimum=#{API_VERSION}][maximum=#{API_VERSION}]", :count => 1
        assert_select "area[maximum=#{APP_CONFIG['max_request_area']}]", :count => 1
        assert_select "tracepoints[per_page=#{APP_CONFIG['tracepoints_per_page']}]", :count => 1
      end
    end
  end
end
