require File.dirname(__FILE__) + '/../test_helper'
require 'api_controller'

# Re-raise errors caught by the controller.
class ApiController; def rescue_action(e) raise e end; end

class ApiControllerTest < Test::Unit::TestCase
  api_fixtures
  
  def setup
    @controller = ApiController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @badbigbbox = %w{ -0.1,-0.1,1.1,1.1 10,10,11,11 }
    @badmalformedbbox = %w{ -0.1  hello S0.1,W0.1,N0.1,E0.1
    10N2W10.1N2.1W }
    @badlatmixedbbox = %w{}
    @badlonmixedbbox = %w{}
    @badlatlonoutboundsbbox = %w{ -190.2,-190.2,-190.1,-190.1 -190.1,89.9,-190,90 }
    @goodbbox = %w{ -0.1,-0.1,0.1,0.1 51.1,-0.1,51.2,0 
    -0.1,%20-0.1,%200.1,%200.1 -0.1edcd,-0.1d,0.1,0.1 -0.1E,-0.1E,0.1S,0.1N }
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
    assert_response :success
    assert_select "osm[version='#{API_VERSION}'][generator='#{GENERATOR}']:root", :count => 1 do
      assert_select "bounds[minlon=#{minlon}][minlat=#{minlat}][maxlon=#{maxlon}][maxlat=#{maxlat}]", :count => 1
      assert_select "node[id=#{node.id}][lat=#{node.lat}][lon=#{node.lon}][version=#{node.version}][changeset=#{node.changeset_id}][visible=#{node.visible}][timestamp=#{node.timestamp.xmlschema}]", :count => 1 do
        # This should really be more generic
        assert_select "tag[k=test][v=1]"
      end
      # Should also test for the ways and relation
    end
  end
  
  def test_map_without_bbox
    ["trackpoints", "map"].each do |tq|
      get tq
      assert_response :bad_request
      assert_equal "The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat", @response.body
    end
  end
  
  def test_traces_page_less_than_0
    -10.upto(-1) do |i|
      get :trackpoints, :page => i, :bbox => "-0.1,-0.1,0.1,0.1"
      assert_response :bad_request
      assert_equal "Page number must be greater than or equal to 0", @response.body
    end
    0.upto(10) do |i|
      get :trackpoints, :page => i, :bbox => "-0.1,-0.1,0.1,0.1"
      assert_response :success
    end
  end
  
  def test_bbox_too_big
    @badbigbbox.each do |bbox|
      [ "trackpoints", "map" ].each do |tq|
        get tq, :bbox => bbox
        assert_response :bad_request, "The bbox:#{bbox} was expected to be too big"
        assert_equal "The maximum bbox size is #{APP_CONFIG['max_request_area']}, and your request was too large. Either request a smaller area, or use planet.osm", @response.body
      end
    end
  end
  
  def test_bbox_malformed
    @badmalformedbbox.each do |bbox|
      [ "trackpoints", "map" ].each do |tq|
        get tq, :bbox => bbox
        assert_response :bad_request, "The bbox:#{bbox} was expected to be malformed"
        assert_equal "The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat", @response.body
      end
    end
  end
  
  def test_bbox_lon_mixedup
    @badlonmixedbbox.each do |bbox|
      [ "trackpoints", "map" ].each do |tq|
        get tq, :bbox => bbox
        assert_response :bad_request, "The bbox:#{bbox} was expected to have the longitude mixed up"
        assert_equal "The minimum longitude must be less than the maximum longitude, but it wasn't", @response.body
      end
    end
  end
  
  def test_bbox_lat_mixedup
    @badlatmixedbbox.each do |bbox|
      ["trackpoints", "map"].each do |tq|
        get tq, :bbox => bbox
        assert_response :bad_request, "The bbox:#{bbox} was expected to have the latitude mixed up"
        assert_equal "The minimum latitude must be less than the maximum latitude, but it wasn't", @response.body
      end
    end
  end
  
  def test_latlon_outofbounds
    @badlatlonoutboundsbbox.each do |bbox|
      [ "trackpoints", "map" ].each do |tq|
        get tq, :bbox => bbox
        #print @request.to_yaml
        assert_response :bad_request, "The bbox was expected to be out of range"
        assert_equal "The latitudes must be between -90 an 90, and longitudes between -180 and 180", @response.body
      end
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
