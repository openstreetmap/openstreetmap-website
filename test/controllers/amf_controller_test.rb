require 'test_helper'
require 'stringio'
include Potlatch

class AmfControllerTest < ActionController::TestCase
  api_fixtures

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/amf/read", :method => :post },
      { :controller => "amf", :action => "amf_read" }
    )
    assert_routing(
      { :path => "/api/0.6/amf/write", :method => :post },
      { :controller => "amf", :action => "amf_write" }
    )
  end

  def test_getway
    # check a visible way
    id = current_ways(:visible_way).id
    amf_content "getway", "/1", [id]
    post :amf_read
    assert_response :success
    amf_parse_response                                         
    way = amf_result("/1")
    assert_equal 0, way[0]
    assert_equal "", way[1]
    assert_equal id, way[2]
    assert_equal 1, way[3].length
    assert_equal 3, way[3][0][2]
    assert_equal 1, way[5]
    assert_equal 2, way[6]
  end

  def test_getway_invisible
    # check an invisible way
    id = current_ways(:invisible_way).id
    amf_content "getway", "/1", [id]
    post :amf_read
    assert_response :success
    amf_parse_response
    way = amf_result("/1")
    assert_equal -4, way[0], -4
    assert_equal "way", way[1]
    assert_equal id, way[2]
    assert way[3].nil? and way[4].nil? and way[5].nil? and way[6].nil?
  end

  def test_getway_with_versions
    # check a way with multiple versions
    id = current_ways(:way_with_versions).id
    amf_content "getway", "/1", [id]
    post :amf_read
    assert_response :success
    amf_parse_response                                         
    way = amf_result("/1")
    assert_equal 0, way[0]
    assert_equal "", way[1]
    assert_equal id, way[2]
    assert_equal 1, way[3].length
    assert_equal 15, way[3][0][2]
    assert_equal 4, way[5]
    assert_equal 2, way[6]
  end

  def test_getway_with_duplicate_nodes
    # check a way with duplicate nodes
    id = current_ways(:way_with_duplicate_nodes).id
    amf_content "getway", "/1", [id]
    post :amf_read
    assert_response :success
    amf_parse_response                                         
    way = amf_result("/1")
    assert_equal 0, way[0]
    assert_equal "", way[1]
    assert_equal id, way[2]
    assert_equal 2, way[3].length
    assert_equal 4, way[3][0][2]
    assert_equal 4, way[3][1][2]
    assert_equal 1, way[5]
    assert_equal 2, way[6]
  end

  def test_getway_with_multiple_nodes
    # check a way with multiple nodes
    id = current_ways(:way_with_multiple_nodes).id
    amf_content "getway", "/1", [id]
    post :amf_read
    assert_response :success
    amf_parse_response                                         
    way = amf_result("/1")
    assert_equal 0, way[0]
    assert_equal "", way[1]
    assert_equal id, way[2]
    assert_equal 3, way[3].length
    assert_equal 4, way[3][0][2]
    assert_equal 15, way[3][1][2]
    assert_equal 6, way[3][2][2]
    assert_equal 2, way[5]
    assert_equal 2, way[6]
  end

  def test_getway_nonexistent
    # check chat a non-existent way is not returned
    amf_content "getway", "/1", [0]
    post :amf_read
    assert_response :success
    amf_parse_response
    way = amf_result("/1")
    assert_equal -4, way[0]
    assert_equal "way", way[1]
    assert_equal 0, way[2]
    assert way[3].nil? and way[4].nil? and way[5].nil? and way[6].nil?
  end

  def test_whichways
    node = current_nodes(:used_node_1)
    minlon = node.lon-0.1
    minlat = node.lat-0.1
    maxlon = node.lon+0.1
    maxlat = node.lat+0.1
    amf_content "whichways", "/1", [minlon, minlat, maxlon, maxlat]
    post :amf_read
    assert_response :success
    amf_parse_response 

    # check contents of message
    map = amf_result "/1"
    assert_equal 0, map[0], 'map error code should be 0'
    assert_equal "", map[1], 'map error text should be empty'

    # check the formatting of the message
    assert_equal 5, map.length, 'map should have length 5'
    assert_equal Array, map[2].class, 'map "ways" element should be an array'
    assert_equal Array, map[3].class, 'map "nodes" element should be an array'
    assert_equal Array, map[4].class, 'map "relations" element should be an array'
    map[2].each do |w|
      assert_equal 2, w.length, 'way should be (id, version) pair'
      assert w[0] == w[0].floor, 'way ID should be an integer'
      assert w[1] == w[1].floor, 'way version should be an integer'
    end

    map[3].each do |n|
      assert_equal 5, w.length, 'node should be (id, lat, lon, [tags], version) tuple'
      assert n[0] == n[0].floor, 'node ID should be an integer'
      assert n[1] >= minlat - 0.01, 'node lat should be greater than min'
      assert n[1] <= maxlat - 0.01, 'node lat should be less than max'
      assert n[2] >= minlon - 0.01, 'node lon should be greater than min'
      assert n[2] <= maxlon - 0.01, 'node lon should be less than max'
      assert_equal Array, a[3].class, 'node tags should be array'
      assert n[4] == n[4].floor, 'node version should be an integer'
    end

    map[4].each do |r|
      assert_equal 2, r.length, 'relation should be (id, version) pair'
      assert r[0] == r[0].floor, 'relation ID should be an integer'
      assert r[1] == r[1].floor, 'relation version should be an integer'
    end

    # TODO: looks like amf_controller changed since this test was written
    # so someone who knows what they're doing should check this!
    ways = map[2].collect { |x| x[0] }
    assert ways.include?(current_ways(:used_way).id),
      "map should include used way"
    assert !ways.include?(current_ways(:invisible_way).id),
      'map should not include deleted way'
  end

  ##
  # checks that too-large a bounding box will not be served.
  def test_whichways_toobig
    bbox = [-0.1,-0.1,1.1,1.1]
    check_bboxes_are_bad [bbox] do |map,bbox|
      assert_boundary_error map, " The server said: The maximum bbox size is 0.25, and your request was too large. Either request a smaller area, or use planet.osm"
    end
  end

  ##
  # checks that an invalid bounding box will not be served. in this case
  # one with max < min latitudes.
  #
  # NOTE: the controller expands the bbox by 0.01 in each direction!
  def test_whichways_badlat
    bboxes = [[0,0.1,0.1,0], [-0.1,80,0.1,70], [0.24,54.35,0.25,54.33]]
    check_bboxes_are_bad bboxes do |map, bbox|
      assert_boundary_error map, " The server said: The minimum latitude must be less than the maximum latitude, but it wasn't", bbox.inspect
    end
  end

  ##
  # same as test_whichways_badlat, but for longitudes
  #
  # NOTE: the controller expands the bbox by 0.01 in each direction!
  def test_whichways_badlon
    bboxes = [[80,-0.1,70,0.1], [54.35,0.24,54.33,0.25]]
    check_bboxes_are_bad bboxes do |map, bbox|
      assert_boundary_error map, " The server said: The minimum longitude must be less than the maximum longitude, but it wasn't", bbox.inspect
    end
  end

  def test_whichways_deleted
    node = current_nodes(:used_node_1)
    minlon = node.lon-0.1
    minlat = node.lat-0.1
    maxlon = node.lon+0.1
    maxlat = node.lat+0.1
    amf_content "whichways_deleted", "/1", [minlon, minlat, maxlon, maxlat]
    post :amf_read
    assert_response :success
    amf_parse_response

    # check contents of message
    map = amf_result "/1"
    assert_equal 0, map[0], 'first map element should be 0'
    assert_equal "", map[1], 'second map element should be an empty string'
    assert_equal Array, map[2].class, 'third map element should be an array'
    # TODO: looks like amf_controller changed since this test was written
    # so someone who knows what they're doing should check this!
    assert !map[2].include?(current_ways(:used_way).id),
      "map should not include used way"
    assert map[2].include?(current_ways(:invisible_way).id),
      'map should include deleted way'
  end

  def test_whichways_deleted_toobig
    bbox = [-0.1,-0.1,1.1,1.1]
    amf_content "whichways_deleted", "/1", bbox
    post :amf_read
    assert_response :success
    amf_parse_response 

    map = amf_result "/1"
    assert_deleted_boundary_error map, " The server said: The maximum bbox size is 0.25, and your request was too large. Either request a smaller area, or use planet.osm"
  end

  def test_getrelation
    id = current_relations(:visible_relation).id
    amf_content "getrelation", "/1", [id]
    post :amf_read
    assert_response :success
    amf_parse_response
    rel = amf_result("/1")
    assert_equal rel[0], 0
    assert_equal rel[2], id
  end

  def test_getrelation_invisible
    id = current_relations(:invisible_relation).id
    amf_content "getrelation", "/1", [id]
    post :amf_read
    assert_response :success
    amf_parse_response
    rel = amf_result("/1")
    assert_equal rel[0], -4
    assert_equal rel[1], "relation"
    assert_equal rel[2], id
    assert rel[3].nil? and rel[4].nil?
  end

  def test_getrelation_nonexistent
    id = 0
    amf_content "getrelation", "/1", [id]
    post :amf_read
    assert_response :success
    amf_parse_response
    rel = amf_result("/1")
    assert_equal rel[0], -4
    assert_equal rel[1], "relation"
    assert_equal rel[2], id
    assert rel[3].nil? and rel[4].nil?
  end

  def test_getway_old
    # try to get the last visible version (specified by <0) (should be current version)
    latest = current_ways(:way_with_versions)
    # NOTE: looks from the API changes that this now expects a timestamp
    # instead of a version number...
    # try to get version 1
    v1 = ways(:way_with_versions_v1)
    { latest.id => '', 
      v1.way_id => v1.timestamp.strftime("%d %b %Y, %H:%M:%S")
    }.each do |id, t|
      amf_content "getway_old", "/1", [id, t]
      post :amf_read      
      assert_response :success
      amf_parse_response
      returned_way = amf_result("/1")
      assert_equal 0, returned_way[0]
      assert_equal id, returned_way[2]
      # API returns the *latest* version, even for old ways...
      assert_equal latest.version, returned_way[5]
    end
  end
  
  ##
  # test that the server doesn't fall over when rubbish is passed
  # into the method args.
  def test_getway_old_invalid
    way_id = current_ways(:way_with_versions).id
    { "foo"  => "bar",
      way_id => "not a date",
      way_id => "2009-03-25 00:00:00", # <- wrong format
      way_id => "0 Jan 2009 00:00:00", # <- invalid date
      -1     => "1 Jan 2009 00:00:00"  # <- invalid ID
    }.each do |id, t|
      amf_content "getway_old", "/1", [id, t]
      post :amf_read
      assert_response :success
      amf_parse_response
      returned_way = amf_result("/1")
      assert_equal -1, returned_way[0]
      assert returned_way[3].nil?
      assert returned_way[4].nil?
      assert returned_way[5].nil?
    end
  end

  def test_getway_old_nonexistent
    # try to get the last version+10 (shoudn't exist)
    v1 = ways(:way_with_versions_v1)
    # try to get last visible version of non-existent way
    # try to get specific version of non-existent way
    [[0, ''], 
     [0, '1 Jan 1970, 00:00:00'], 
     [v1.way_id, (v1.timestamp - 10).strftime("%d %b %Y, %H:%M:%S")]
    ].each do |id, t|
      amf_content "getway_old", "/1", [id, t]
      post :amf_read
      assert_response :success
      amf_parse_response
      returned_way = amf_result("/1")
      assert_equal -1, returned_way[0]
      assert returned_way[3].nil?
      assert returned_way[4].nil?
      assert returned_way[5].nil?
    end
  end

  def test_getway_history
    latest = current_ways(:way_with_versions)
    oldest = ways(:way_with_versions_v1)

    amf_content "getway_history", "/1", [latest.id]
    post :amf_read
    assert_response :success
    amf_parse_response
    history = amf_result("/1")

    # ['way',wayid,history]
    assert_equal 'way', history[0]
    assert_equal latest.id, history[1] 
    # We use dates rather than version numbers here, because you might
    # have moved a node within a way (i.e. way version not incremented).
    # The timestamp is +1 because we say "give me the revision of 15:33:02",
    # but that might actually include changes at 15:33:02.457.
    assert_equal (latest.timestamp + 1).strftime("%d %b %Y, %H:%M:%S"), history[2].first[0]
    assert_equal (oldest.timestamp + 1).strftime("%d %b %Y, %H:%M:%S"), history[2].last[0]
  end

  def test_getway_history_nonexistent
    amf_content "getway_history", "/1", [0]
    post :amf_read
    assert_response :success
    amf_parse_response
    history = amf_result("/1")

    # ['way',wayid,history]
    assert_equal history[0], 'way'
    assert_equal history[1], 0
    assert history[2].empty?
  end

  def test_getnode_history
    latest = current_nodes(:node_with_versions)
    amf_content "getnode_history", "/1", [latest.id]
    post :amf_read
    assert_response :success
    amf_parse_response
    history = amf_result("/1")

    # ['node',nodeid,history]
    # note that (as per getway_history) we actually round up
    # to the next second
    assert_equal history[0], 'node', 
      'first element should be "node"'
    assert_equal history[1], latest.id,
      'second element should be the input node ID'
    assert_equal history[2].first[0], 
      (latest.timestamp + 1).strftime("%d %b %Y, %H:%M:%S"),
      'first element in third element (array) should be the latest version'
    assert_equal history[2].last[0], 
      (nodes(:node_with_versions_v1).timestamp + 1).strftime("%d %b %Y, %H:%M:%S"),
      'last element in third element (array) should be the initial version'
  end

  def test_getnode_history_nonexistent
    amf_content "getnode_history", "/1", [0]
    post :amf_read
    assert_response :success
    amf_parse_response
    history = amf_result("/1")

    # ['node',nodeid,history]
    assert_equal history[0], 'node'
    assert_equal history[1], 0
    assert history[2].empty?
  end

  # ************************************************************
  # AMF Write tests
  def test_putpoi_update_valid
    nd = current_nodes(:visible_node)
    cs_id = changesets(:public_user_first_change).id
    amf_content "putpoi", "/1", ["test@example.com:test", cs_id, nd.version, nd.id, nd.lon, nd.lat, nd.tags, nd.visible]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal nd.id, result[2]
    assert_equal nd.id, result[3]
    assert_equal nd.version+1, result[4]
    
    # Now try to update again, with a different lat/lon, using the updated version number
    lat = nd.lat+0.1
    lon = nd.lon-0.1
    amf_content "putpoi", "/2", ["test@example.com:test", cs_id, nd.version+1, nd.id, lon, lat, nd.tags, nd.visible]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/2")
    
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal nd.id, result[2]
    assert_equal nd.id, result[3]
    assert_equal nd.version+2, result[4]
  end
  
  # Check that we can create a no valid poi
  # Using similar method for the node controller test
  def test_putpoi_create_valid
    # This node has no tags
    nd = Node.new
    # create a node with random lat/lon
    lat = rand(100)-50 + rand
    lon = rand(100)-50 + rand
    # normal user has a changeset open
    changeset = changesets(:public_user_first_change)
    
    amf_content "putpoi", "/1", ["test@example.com:test", changeset.id, nil, nil, lon, lat, {}, nil]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    
    # check the array returned by the amf
    assert_equal 5, result.size
    assert_equal 0, result[0], "expected to get the status ok from the amf"
    assert_equal 0, result[2], "The old id should be 0"
    assert result[3] > 0, "The new id should be greater than 0"
    assert_equal 1, result[4], "The new version should be 1"
    
    # Finally check that the node that was saved has saved the data correctly 
    # in both the current and history tables
    # First check the current table
    current_node = Node.find(result[3].to_i)
    assert_in_delta lat, current_node.lat, 0.00001, "The latitude was not retreieved correctly"
    assert_in_delta lon, current_node.lon, 0.00001, "The longitude was not retreived correctly"
    assert_equal 0, current_node.tags.size, "There seems to be a tag that has been added to the node"
    assert_equal result[4], current_node.version, "The version returned, is different to the one returned by the amf"
    # Now check the history table
    historic_nodes = Node.where(:id => result[3])
    assert_equal 1, historic_nodes.size, "There should only be one historic node created"
    first_historic_node = historic_nodes.first
    assert_in_delta lat, first_historic_node.lat, 0.00001, "The latitude was not retreived correctly"
    assert_in_delta lon, first_historic_node.lon, 0.00001, "The longitude was not retreuved correctly"
    assert_equal 0, first_historic_node.tags.size, "There seems to be a tag that have been attached to this node"
    assert_equal result[4], first_historic_node.version, "The version returned, is different to the one returned by the amf"
    
    ####
    # This node has some tags
    tnd = Node.new
    # create a node with random lat/lon
    lat = rand(100)-50 + rand
    lon = rand(100)-50 + rand
    # normal user has a changeset open
    changeset = changesets(:public_user_first_change)
    
    amf_content "putpoi", "/2", ["test@example.com:test", changeset.id, nil, nil, lon, lat, { "key" => "value", "ping" => "pong" }, nil]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/2")

    # check the array returned by the amf
    assert_equal 5, result.size
    assert_equal 0, result[0], "Expected to get the status ok in the amf"
    assert_equal 0, result[2], "The old id should be 0"
    assert result[3] > 0, "The new id should be greater than 0"
    assert_equal 1, result[4], "The new version should be 1"
    
    # Finally check that the node that was saved has saved the data correctly 
    # in both the current and history tables
    # First check the current table
    current_node = Node.find(result[3].to_i)
    assert_in_delta lat, current_node.lat, 0.00001, "The latitude was not retreieved correctly"
    assert_in_delta lon, current_node.lon, 0.00001, "The longitude was not retreived correctly"
    assert_equal 2, current_node.tags.size, "There seems to be a tag that has been added to the node"
    assert_equal({ "key" => "value", "ping" => "pong" }, current_node.tags, "tags are different")
    assert_equal result[4], current_node.version, "The version returned, is different to the one returned by the amf"
    # Now check the history table
    historic_nodes = Node.where(:id => result[3])
    assert_equal 1, historic_nodes.size, "There should only be one historic node created"
    first_historic_node = historic_nodes.first
    assert_in_delta lat, first_historic_node.lat, 0.00001, "The latitude was not retreived correctly"
    assert_in_delta lon, first_historic_node.lon, 0.00001, "The longitude was not retreuved correctly"
    assert_equal 2, first_historic_node.tags.size, "There seems to be a tag that have been attached to this node"
    assert_equal({ "key" => "value", "ping" => "pong" }, first_historic_node.tags, "tags are different")
    assert_equal result[4], first_historic_node.version, "The version returned, is different to the one returned by the amf"
  end
  
  # try creating a POI with rubbish in the tags
  def test_putpoi_create_with_control_chars
    # This node has no tags
    nd = Node.new
    # create a node with random lat/lon
    lat = rand(100)-50 + rand
    lon = rand(100)-50 + rand
    # normal user has a changeset open
    changeset = changesets(:public_user_first_change)
    
    mostly_invalid = (0..31).to_a.map {|i| i.chr}.join
    tags = { "something" => "foo#{mostly_invalid}bar" }
      
    amf_content "putpoi", "/1", ["test@example.com:test", changeset.id, nil, nil, lon, lat, tags, nil]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
      
    # check the array returned by the amf
    assert_equal 5, result.size
    assert_equal 0, result[0], "Expected to get the status ok in the amf"
    assert_equal 0, result[2], "The old id should be 0"
    assert result[3] > 0, "The new id should be greater than 0"
    assert_equal 1, result[4], "The new version should be 1"
    
    # Finally check that the node that was saved has saved the data correctly 
    # in both the current and history tables
    # First check the current table
    current_node = Node.find(result[3].to_i)
    assert_equal 1, current_node.tags.size, "There seems to be a tag that has been added to the node"
    assert_equal({ "something" => "foo\t\n\rbar" }, current_node.tags, "tags were not fixed correctly")
    assert_equal result[4], current_node.version, "The version returned, is different to the one returned by the amf"
  end

  # try creating a POI with rubbish in the tags
  def test_putpoi_create_with_invalid_utf8
    # This node has no tags
    nd = Node.new
    # create a node with random lat/lon
    lat = rand(100)-50 + rand
    lon = rand(100)-50 + rand
    # normal user has a changeset open
    changeset = changesets(:public_user_first_change)
    
    invalid = "\xc0\xc0"
    tags = { "something" => "foo#{invalid}bar" }
      
    amf_content "putpoi", "/1", ["test@example.com:test", changeset.id, nil, nil, lon, lat, tags, nil]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 2, result.size
    assert_equal -1, result[0], "Expected to get the status FAIL in the amf"
    assert_equal "One of the tags is invalid. Linux users may need to upgrade to Flash Player 10.1.", result[1] 
  end
      
  def test_putpoi_delete_valid
    
  end
  
  def test_putpoi_delete_already_deleted
    
  end
  
  def test_putpoi_delete_not_found
    
  end
  
  def test_putpoi_invalid_latlon
    
  end

  def test_startchangeset_invalid_xmlchar_comment
    invalid = "\035\022"
    comment = "foo#{invalid}bar"
      
    amf_content "startchangeset", "/1", ["test@example.com:test", Hash.new, nil, comment, 1]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 3, result.size, result.inspect
    assert_equal 0, result[0]
    new_cs_id = result[2].to_i

    cs = Changeset.find(new_cs_id)
    assert_equal "foobar", cs.tags["comment"]
  end

  # ************************************************************
  # AMF Helper functions

  # Get the result record for the specified ID
  # It's an assertion FAIL if the record does not exist
  def amf_result ref
    assert @amf_result.has_key?("#{ref}/onResult")
    @amf_result["#{ref}/onResult"]
  end

  # Encode the AMF message to invoke "target" with parameters as
  # the passed data. The ref is used to retrieve the results.
  def amf_content(target, ref, data)
    a,b=1.divmod(256)
    c = StringIO.new()
    c.write 0.chr+0.chr   # version 0
    c.write 0.chr+0.chr   # n headers
    c.write a.chr+b.chr   # n bodies
    c.write AMF.encodestring(target)
    c.write AMF.encodestring(ref)
    c.write [-1].pack("N")
    c.write AMF.encodevalue(data)

    @request.env["RAW_POST_DATA"] = c.string
  end

  # Parses the @response object as an AMF messsage.
  # The result is a hash of message_ref => data.
  # The attribute @amf_result is initialised to this hash.
  def amf_parse_response
    req = StringIO.new(@response.body)

    req.read(2)   # version

    # parse through any headers
	headers=AMF.getint(req)					# Read number of headers
	headers.times do						# Read each header
	  name=AMF.getstring(req)				#  |
	  req.getc				   				#  | skip boolean
	  value=AMF.getvalue(req)				#  |
	end

    # parse through responses
    results = {}
    bodies=AMF.getint(req)					# Read number of bodies
	bodies.times do							# Read each body
	  message=AMF.getstring(req)			#  | get message name
	  index=AMF.getstring(req)				#  | get index in response sequence
	  bytes=AMF.getlong(req)				#  | get total size in bytes
	  args=AMF.getvalue(req)				#  | get response (probably an array)
      results[message] = args
    end
    @amf_result = results
    results
  end

  ##
  # given an array of bounding boxes (each an array of 4 floats), call the
  # AMF "whichways" controller for each and pass the result back to the
  # caller's block for assertion testing.
  def check_bboxes_are_bad(bboxes)
    bboxes.each do |bbox|
      amf_content "whichways", "/1", bbox
      post :amf_read
      assert_response :success
      amf_parse_response

      # pass the response back to the caller's block to be tested
      # against what the caller expected.
      map = amf_result "/1"
      yield map, bbox
    end
  end
  
  # this should be what AMF controller returns when the bbox of a
  # whichways request is invalid or too large.
  def assert_boundary_error(map, msg=nil, error_hint=nil)
    expected_map = [-2, "Sorry - I can't get the map for that area.#{msg}"]
    assert_equal expected_map, map, "AMF controller should have returned an error. (#{error_hint})"
  end

  # this should be what AMF controller returns when the bbox of a
  # whichways_deleted request is invalid or too large.
  def assert_deleted_boundary_error(map, msg=nil, error_hint=nil)
    expected_map = [-2, "Sorry - I can't get the map for that area.#{msg}"]
    assert_equal expected_map, map, "AMF controller should have returned an error. (#{error_hint})"
  end
end
