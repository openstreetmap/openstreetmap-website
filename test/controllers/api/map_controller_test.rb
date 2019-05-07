require "test_helper"

module Api
  class MapControllerTest < ActionController::TestCase
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
        { :path => "/api/0.6/map", :method => :get },
        { :controller => "api/map", :action => "index", :format => "xml" }
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
      get :index, :params => { :bbox => bbox }, :format => :xml
      if $VERBOSE
        print @request.to_yaml
        print @response.body
      end
      assert_response :success, "Expected scucess with the map call"
      assert_select "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", :count => 1 do
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
      get :index, :params => { :bbox => bbox }, :format => :xml
      assert_response :success, "The map call should have succeeded"
      assert_select "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", :count => 1 do
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
      get :index, :params => { :bbox => bbox }, :format => :xml
      assert_response :success, "The map call should have succeeded"
      assert_select "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", :count => 1 do
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
      get :index, :params => { :bbox => "179.998,89.998,179.999.1,89.999" }, :format => :xml
      assert_response :success, "The map call should have succeeded"
      assert_select "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", :count => 1 do
        assert_select "bounds[minlon='179.9980000'][minlat='89.9980000'][maxlon='179.9990000'][maxlat='89.9990000']", :count => 1
        assert_select "node", :count => 0
        assert_select "way", :count => 0
        assert_select "relation", :count => 0
      end
    end

    def test_map_without_bbox
      get :index
      assert_response :bad_request
      assert_equal "The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat", @response.body, "A bbox param was expected"
    end

    def test_bbox_too_big
      @badbigbbox.each do |bbox|
        get :index, :params => { :bbox => bbox }, :format => :xml
        assert_response :bad_request, "The bbox:#{bbox} was expected to be too big"
        assert_equal "The maximum bbox size is #{Settings.max_request_area}, and your request was too large. Either request a smaller area, or use planet.osm", @response.body, "bbox: #{bbox}"
      end
    end

    def test_bbox_malformed
      @badmalformedbbox.each do |bbox|
        get :index, :params => { :bbox => bbox }, :format => :xml
        assert_response :bad_request, "The bbox:#{bbox} was expected to be malformed"
        assert_equal "The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat", @response.body, "bbox: #{bbox}"
      end
    end

    def test_bbox_lon_mixedup
      @badlonmixedbbox.each do |bbox|
        get :index, :params => { :bbox => bbox }, :format => :xml
        assert_response :bad_request, "The bbox:#{bbox} was expected to have the longitude mixed up"
        assert_equal "The minimum longitude must be less than the maximum longitude, but it wasn't", @response.body, "bbox: #{bbox}"
      end
    end

    def test_bbox_lat_mixedup
      @badlatmixedbbox.each do |bbox|
        get :index, :params => { :bbox => bbox }, :format => :xml
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
  end
end
