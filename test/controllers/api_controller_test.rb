require "test_helper"

class ApiControllerTest < ActionController::TestCase
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
      { :path => "/api/0.6/permissions", :method => :get },
      { :controller => "api", :action => "permissions" }
    )
    assert_routing(
      { :path => "/api/0.6/map", :method => :get },
      { :controller => "api", :action => "map" }
    )
    assert_routing(
      { :path => "/api/0.6/changes", :method => :get },
      { :controller => "api", :action => "changes" }
    )
  end

  # -------------------------------------
  # Test reading a bounding box.
  # -------------------------------------

  def test_map
    node = create(:node, :lat => 7, :lon => 7)
    tag = create(:node_tag, :node => node)
    way1 = create(:way_node, :node => node).way
    way2 = create(:way_node, :node => node).way
    relation = create(:relation_member, :member => node).relation

    # Need to split the min/max lat/lon out into their own variables here
    # so that we can test they are returned later.
    minlon = node.lon - 0.1
    minlat = node.lat - 0.1
    maxlon = node.lon + 0.1
    maxlat = node.lat + 0.1
    bbox = "#{minlon},#{minlat},#{maxlon},#{maxlat}"
    get :map, :params => { :bbox => bbox }
    if $VERBOSE
      print @request.to_yaml
      print @response.body
    end
    assert_response :success, "Expected scucess with the map call"
    assert_select "osm[version='#{API_VERSION}'][generator='#{GENERATOR}']", :count => 1 do
      assert_select "bounds[minlon='#{format('%.7f', minlon)}'][minlat='#{format('%.7f', minlat)}'][maxlon='#{format('%.7f', maxlon)}'][maxlat='#{format('%.7f', maxlat)}']", :count => 1
      assert_select "node[id='#{node.id}'][lat='#{format('%.7f', node.lat)}'][lon='#{format('%.7f', node.lon)}'][version='#{node.version}'][changeset='#{node.changeset_id}'][visible='#{node.visible}'][timestamp='#{node.timestamp.xmlschema}']", :count => 1 do
        # This should really be more generic
        assert_select "tag[k='#{tag.k}'][v='#{tag.v}']"
      end
      assert_select "way", :count => 2
      assert_select "way[id='#{way1.id}']", :count => 1
      assert_select "way[id='#{way2.id}']", :count => 1
      assert_select "relation", :count => 1
      assert_select "relation[id='#{relation.id}']", :count => 1
    end
  end

  # This differs from the above test in that we are making the bbox exactly
  # the same as the node we are looking at
  def test_map_inclusive
    node = create(:node, :lat => 7, :lon => 7)
    tag = create(:node_tag, :node => node)
    way1 = create(:way_node, :node => node).way
    way2 = create(:way_node, :node => node).way
    relation = create(:relation_member, :member => node).relation

    bbox = "#{node.lon},#{node.lat},#{node.lon},#{node.lat}"
    get :map, :params => { :bbox => bbox }
    assert_response :success, "The map call should have succeeded"
    assert_select "osm[version='#{API_VERSION}'][generator='#{GENERATOR}']", :count => 1 do
      assert_select "bounds[minlon='#{node.lon}'][minlat='#{node.lat}'][maxlon='#{node.lon}'][maxlat='#{node.lat}']", :count => 1
      assert_select "node[id='#{node.id}'][lat='#{format('%.7f', node.lat)}'][lon='#{format('%.7f', node.lon)}'][version='#{node.version}'][changeset='#{node.changeset_id}'][visible='#{node.visible}'][timestamp='#{node.timestamp.xmlschema}']", :count => 1 do
        # This should really be more generic
        assert_select "tag[k='#{tag.k}'][v='#{tag.v}']"
      end
      assert_select "way", :count => 2
      assert_select "way[id='#{way1.id}']", :count => 1
      assert_select "way[id='#{way2.id}']", :count => 1
      assert_select "relation", :count => 1
      assert_select "relation[id='#{relation.id}']", :count => 1
    end
  end

  def test_map_complete_way
    node = create(:node, :lat => 7, :lon => 7)
    # create a couple of nodes well outside of the bbox
    node2 = create(:node, :lat => 45, :lon => 45)
    node3 = create(:node, :lat => 10, :lon => 10)
    way1 = create(:way_node, :node => node).way
    create(:way_node, :way => way1, :node => node2, :sequence_id => 2)
    way2 = create(:way_node, :node => node).way
    create(:way_node, :way => way2, :node => node3, :sequence_id => 2)
    relation = create(:relation_member, :member => way1).relation

    bbox = "#{node.lon},#{node.lat},#{node.lon},#{node.lat}"
    get :map, :params => { :bbox => bbox }
    assert_response :success, "The map call should have succeeded"
    assert_select "osm[version='#{API_VERSION}'][generator='#{GENERATOR}']", :count => 1 do
      assert_select "bounds[minlon='#{node.lon}'][minlat='#{node.lat}'][maxlon='#{node.lon}'][maxlat='#{node.lat}']", :count => 1
      assert_select "node", :count => 3
      assert_select "node[id='#{node.id}']", :count => 1
      assert_select "node[id='#{node2.id}']", :count => 1
      assert_select "node[id='#{node3.id}']", :count => 1
      assert_select "way", :count => 2
      assert_select "way[id='#{way1.id}']", :count => 1
      assert_select "way[id='#{way2.id}']", :count => 1
      assert_select "relation", :count => 1
      assert_select "relation[id='#{relation.id}']", :count => 1
    end
  end

  def test_map_empty
    get :map, :params => { :bbox => "179.998,89.998,179.999.1,89.999" }
    assert_response :success, "The map call should have succeeded"
    assert_select "osm[version='#{API_VERSION}'][generator='#{GENERATOR}']", :count => 1 do
      assert_select "bounds[minlon='179.9980000'][minlat='89.9980000'][maxlon='179.9990000'][maxlat='89.9990000']", :count => 1
      assert_select "node", :count => 0
      assert_select "way", :count => 0
      assert_select "relation", :count => 0
    end
  end

  def test_map_without_bbox
    get :map
    assert_response :bad_request
    assert_equal "The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat", @response.body, "A bbox param was expected"
  end

  def test_bbox_too_big
    @badbigbbox.each do |bbox|
      get :map, :params => { :bbox => bbox }
      assert_response :bad_request, "The bbox:#{bbox} was expected to be too big"
      assert_equal "The maximum bbox size is #{MAX_REQUEST_AREA}, and your request was too large. Either request a smaller area, or use planet.osm", @response.body, "bbox: #{bbox}"
    end
  end

  def test_bbox_malformed
    @badmalformedbbox.each do |bbox|
      get :map, :params => { :bbox => bbox }
      assert_response :bad_request, "The bbox:#{bbox} was expected to be malformed"
      assert_equal "The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat", @response.body, "bbox: #{bbox}"
    end
  end

  def test_bbox_lon_mixedup
    @badlonmixedbbox.each do |bbox|
      get :map, :params => { :bbox => bbox }
      assert_response :bad_request, "The bbox:#{bbox} was expected to have the longitude mixed up"
      assert_equal "The minimum longitude must be less than the maximum longitude, but it wasn't", @response.body, "bbox: #{bbox}"
    end
  end

  def test_bbox_lat_mixedup
    @badlatmixedbbox.each do |bbox|
      get :map, :params => { :bbox => bbox }
      assert_response :bad_request, "The bbox:#{bbox} was expected to have the latitude mixed up"
      assert_equal "The minimum latitude must be less than the maximum latitude, but it wasn't", @response.body, "bbox: #{bbox}"
    end
  end

  # We can't actually get an out of bounds error, as the bbox is sanitised.
  # def test_latlon_outofbounds
  #  @badlatlonoutboundsbbox.each do |bbox|
  #    [ "trackpoints", "map" ].each do |tq|
  #      get tq, :bbox => bbox
  #      #print @request.to_yaml
  #      assert_response :bad_request, "The bbox #{bbox} was expected to be out of range"
  #      assert_equal "The latitudes must be between -90 an 90, and longitudes between -180 and 180", @response.body, "bbox: #{bbox}"
  #    end
  #  end
  # end

  # MySQL and Postgres require that the C based functions are installed for
  # this test to work. More information is available from:
  # http://wiki.openstreetmap.org/wiki/Rails#Installing_the_quadtile_functions
  # or by looking at the readme in db/README
  def test_changes_simple
    # create a selection of nodes
    (1..5).each do |n|
      create(:node, :timestamp => Time.utc(2007, 1, 1, 0, 0, 0), :lat => n, :lon => n)
    end
    # deleted nodes should also be counted
    create(:node, :deleted, :timestamp => Time.utc(2007, 1, 1, 0, 0, 0), :lat => 6, :lon => 6)
    # nodes in the same tile won't change the total
    create(:node, :timestamp => Time.utc(2007, 1, 1, 0, 0, 0), :lat => 6, :lon => 6)
    # nodes with a different timestamp should be ignored
    create(:node, :timestamp => Time.utc(2008, 1, 1, 0, 0, 0), :lat => 7, :lon => 7)

    travel_to Time.utc(2010, 4, 3, 10, 55, 0) do
      get :changes
      assert_response :success
      now = Time.now.getutc
      hourago = now - 1.hour
      assert_select "osm[version='#{API_VERSION}'][generator='#{GENERATOR}']", :count => 1 do
        assert_select "changes[starttime='#{hourago.xmlschema}'][endtime='#{now.xmlschema}']", :count => 1 do
          assert_select "tile", :count => 0
        end
      end
    end

    travel_to Time.utc(2007, 1, 1, 0, 30, 0) do
      get :changes
      assert_response :success
      # print @response.body
      # As we have loaded the fixtures, we can assume that there are some
      # changes at the time we have frozen at
      now = Time.now.getutc
      hourago = now - 1.hour
      assert_select "osm[version='#{API_VERSION}'][generator='#{GENERATOR}']", :count => 1 do
        assert_select "changes[starttime='#{hourago.xmlschema}'][endtime='#{now.xmlschema}']", :count => 1 do
          assert_select "tile", :count => 6
        end
      end
    end
  end

  def test_changes_zoom_invalid
    zoom_to_test = %w[p -1 0 17 one two]
    zoom_to_test.each do |zoom|
      get :changes, :params => { :zoom => zoom }
      assert_response :bad_request
      assert_equal @response.body, "Requested zoom is invalid, or the supplied start is after the end time, or the start duration is more than 24 hours"
    end
  end

  def test_changes_zoom_valid
    1.upto(16) do |zoom|
      get :changes, :params => { :zoom => zoom }
      assert_response :success
      # NOTE: there was a test here for the timing, but it was too sensitive to be a good test
      # and it was annoying.
      assert_select "osm[version='#{API_VERSION}'][generator='#{GENERATOR}']", :count => 1 do
        assert_select "changes", :count => 1
      end
    end
  end

  def test_changes_hours_invalid
    invalid = %w[-21 335 -1 0 25 26 100 one two three ping pong :]
    invalid.each do |hour|
      get :changes, :params => { :hours => hour }
      assert_response :bad_request, "Problem with the hour: #{hour}"
      assert_equal @response.body, "Requested zoom is invalid, or the supplied start is after the end time, or the start duration is more than 24 hours", "Problem with the hour: #{hour}."
    end
  end

  def test_changes_hours_valid
    1.upto(24) do |hour|
      get :changes, :params => { :hours => hour }
      assert_response :success
    end
  end

  def test_changes_start_end_invalid
    get :changes, :params => { :start => "2010-04-03 10:55:00", :end => "2010-04-03 09:55:00" }
    assert_response :bad_request
    assert_equal @response.body, "Requested zoom is invalid, or the supplied start is after the end time, or the start duration is more than 24 hours"
  end

  def test_changes_start_end_valid
    get :changes, :params => { :start => "2010-04-03 09:55:00", :end => "2010-04-03 10:55:00" }
    assert_response :success
  end

  def test_permissions_anonymous
    get :permissions
    assert_response :success
    assert_select "osm > permissions", :count => 1 do
      assert_select "permission", :count => 0
    end
  end

  def test_permissions_basic_auth
    basic_authorization create(:user).email, "test"
    get :permissions
    assert_response :success
    assert_select "osm > permissions", :count => 1 do
      assert_select "permission", :count => ClientApplication.all_permissions.size
      ClientApplication.all_permissions.each do |p|
        assert_select "permission[name='#{p}']", :count => 1
      end
    end
  end

  def test_permissions_oauth
    @request.env["oauth.token"] = AccessToken.new do |token|
      # Just to test a few
      token.allow_read_prefs = true
      token.allow_write_api = true
      token.allow_read_gpx = false
    end
    get :permissions
    assert_response :success
    assert_select "osm > permissions", :count => 1 do
      assert_select "permission", :count => 2
      assert_select "permission[name='allow_read_prefs']", :count => 1
      assert_select "permission[name='allow_write_api']", :count => 1
      assert_select "permission[name='allow_read_gpx']", :count => 0
    end
  end
end
