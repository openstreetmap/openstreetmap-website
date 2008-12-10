require File.dirname(__FILE__) + '/../test_helper'
require 'stringio'
include Potlatch

class AmfControllerTest < ActionController::TestCase
  api_fixtures

  # this should be what AMF controller returns when the bbox of a request
  # is invalid or too large.
  BOUNDARY_ERROR = [-2,"Sorry - I can't get the map for that area."]

  def test_getway
    # check a visible way
    id = current_ways(:visible_way).id
    amf_content "getway", "/1", [id]
    post :amf_read
    assert_response :success
    amf_parse_response                                         
    assert_equal amf_result("/1")[0], id
  end

  def test_getway_invisible
    # check an invisible way
    id = current_ways(:invisible_way).id
    amf_content "getway", "/1", [id]
    post :amf_read
    assert_response :success
    amf_parse_response
    way = amf_result("/1")
    assert_equal way[0], id
    assert way[1].empty? and way[2].empty?
  end

  def test_getway_nonexistent
    # check chat a non-existent way is not returned
    amf_content "getway", "/1", [0]
    post :amf_read
    assert_response :success
    amf_parse_response
    way = amf_result("/1")
    assert_equal way[0], 0
    assert way[1].empty? and way[2].empty?
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
    assert_equal 0, map[0], 'first map element should be 0'
    assert_equal Array, map[1].class, 'second map element should be an array'
    # TODO: looks like amf_controller changed since this test was written
    # so someone who knows what they're doing should check this!
    ways = map[1].collect { |x| x[0] }
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
      assert_equal BOUNDARY_ERROR, map, "AMF controller should have returned an error."
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
      assert_equal BOUNDARY_ERROR, map, "AMF controller should have returned an error #{bbox.inspect}."
    end
  end

  ##
  # same as test_whichways_badlat, but for longitudes
  #
  # NOTE: the controller expands the bbox by 0.01 in each direction!
  def test_whichways_badlon
    bboxes = [[80,-0.1,70,0.1], [54.35,0.24,54.33,0.25]]
    check_bboxes_are_bad bboxes do |map, bbox|
      assert_equal BOUNDARY_ERROR, map, "AMF controller should have returned an error #{bbox.inspect}."
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
    assert_equal Array, map[1].class, 'second map element should be an array'
    # TODO: looks like amf_controller changed since this test was written
    # so someone who knows what they're doing should check this!
    assert !map[1].include?(current_ways(:used_way).id),
      "map should not include used way"
    assert map[1].include?(current_ways(:invisible_way).id),
      'map should include deleted way'
  end

  def test_whichways_deleted_toobig
    bbox = [-0.1,-0.1,1.1,1.1]
    amf_content "whichways_deleted", "/1", bbox
    post :amf_read
    assert_response :success
    amf_parse_response 

    map = amf_result "/1"
    assert_equal BOUNDARY_ERROR, map, "AMF controller should have returned an error."
  end

  def test_getrelation
    id = current_relations(:visible_relation).id
    amf_content "getrelation", "/1", [id]
    post :amf_read
    assert_response :success
    amf_parse_response
    assert_equal amf_result("/1")[0], id
  end

  def test_getrelation_invisible
    id = current_relations(:invisible_relation).id
    amf_content "getrelation", "/1", [id]
    post :amf_read
    assert_response :success
    amf_parse_response
    rel = amf_result("/1")
    assert_equal rel[0], id
    assert rel[1].empty? and rel[2].empty?
  end

  def test_getrelation_nonexistent
    id = 0
    amf_content "getrelation", "/1", [id]
    post :amf_read
    assert_response :success
    amf_parse_response
    rel = amf_result("/1")
    assert_equal rel[0], id
    assert rel[1].empty? and rel[2].empty?
  end

  def test_getway_old
    # try to get the last visible version (specified by <0) (should be current version)
    latest = current_ways(:way_with_versions)
    # try to get version 1
    v1 = ways(:way_with_versions_v1)
    {latest => -1, v1 => v1.version}.each do |way, v|
      amf_content "getway_old", "/1", [way.id, v]
      post :amf_read
      assert_response :success
      amf_parse_response
      returned_way = amf_result("/1")
      assert_equal returned_way[1], way.id
      assert_equal returned_way[4], way.version
    end
  end

  def test_getway_old_nonexistent
    # try to get the last version+10 (shoudn't exist)
    latest = current_ways(:way_with_versions)
    # try to get last visible version of non-existent way
    # try to get specific version of non-existent way
    {nil => -1, nil => 1, latest => latest.version + 10}.each do |way, v|
      amf_content "getway_old", "/1", [way.nil? ? 0 : way.id, v]
      post :amf_read
      assert_response :success
      amf_parse_response
      returned_way = amf_result("/1")
      assert returned_way[2].empty?
      assert returned_way[3].empty?
      assert returned_way[4] < 0
    end
  end

  def test_getway_history
    latest = current_ways(:way_with_versions)
    amf_content "getway_history", "/1", [latest.id]
    post :amf_read
    assert_response :success
    amf_parse_response
    history = amf_result("/1")

    # ['way',wayid,history]
    assert_equal history[0], 'way'
    assert_equal history[1], latest.id
    assert_equal history[2].first[0], latest.version
    assert_equal history[2].last[0], ways(:way_with_versions_v1).version
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
    assert_equal history[0], 'node', 
      'first element should be "node"'
    assert_equal history[1], latest.id,
      'second element should be the input node ID'
    # NOTE: changed this test to match what amf_controller actually 
    # outputs - which may or may not be what potlatch is expecting.
    # someone who knows potlatch (i.e: richard f) should review this.
    assert_equal history[2].first[0], latest.version,
      'first part of third element should be the latest version'
    assert_equal history[2].last[0], 
      nodes(:node_with_versions_v1).version,
      'second part of third element should be the initial version'
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
    amf_content "putpoi", "/1", ["test@openstreetmap.org:test", nd.changeset_id, nd.version, nd.id, nd.lon, nd.lat, nd.tags, nd.visible]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    
    assert_equal 0, result[0]
    assert_equal nd.id, result[1]
    assert_equal nd.id, result[2]
    assert_equal nd.version+1, result[3]
    
    # Now try to update again, with a different lat/lon, using the updated version number
    lat = nd.lat+0.1
    lon = nd.lon-0.1
    amf_content "putpoi", "/2", ["test@openstreetmap.org:test", nd.changeset_id, nd.version+1, nd.id, lon, lat, nd.tags, nd.visible]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/2")
    
    assert_equal 0, result[0]
    assert_equal nd.id, result[1]
    assert_equal nd.id, result[2]
    assert_equal nd.version+2, result[3]
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
    changeset = changesets(:normal_user_first_change)
    
    amf_content "putpoi", "/1", ["test@openstreetmap.org:test", changeset.id, nil, nil, lon, lat, {}, nil]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    
    # check the array returned by the amf
    assert_equal 4, result.size
    assert_equal 0, result[0], "expected to get the status ok from the amf"
    assert_equal 0, result[1], "The old id should be 0"
    assert result[2] > 0, "The new id should be greater than 0"
    assert_equal 1, result[3], "The new version should be 1"
    
    # Finally check that the node that was saved has saved the data correctly 
    # in both the current and history tables
    # First check the current table
    current_node = Node.find(result[2])
    assert_in_delta lat, current_node.lat, 0.00001, "The latitude was not retreieved correctly"
    assert_in_delta lon, current_node.lon, 0.00001, "The longitude was not retreived correctly"
    assert_equal 0, current_node.tags.size, "There seems to be a tag that has been added to the node"
    assert_equal result[3], current_node.version, "The version returned, is different to the one returned by the amf"
    # Now check the history table
    historic_nodes = Node.find(:all, :conditions => { :id => result[2] })
    assert_equal 1, historic_nodes.size, "There should only be one historic node created"
    first_historic_node = historic_nodes.first
    assert_in_delta lat, first_historic_node.lat, 0.00001, "The latitude was not retreived correctly"
    assert_in_delta lon, first_historic_node.lon, 0.00001, "The longitude was not retreuved correctly"
    assert_equal 0, first_historic_node.tags.size, "There seems to be a tag that have been attached to this node"
    assert_equal result[3], first_historic_node.version, "The version returned, is different to the one returned by the amf"
    
    ####
    # This node has some tags
    tnd = Node.new
    # create a node with random lat/lon
    lat = rand(100)-50 + rand
    lon = rand(100)-50 + rand
    # normal user has a changeset open
    changeset = changesets(:normal_user_first_change)
    
    amf_content "putpoi", "/2", ["test@openstreetmap.org:test", changeset.id, nil, nil, lon, lat, { "key" => "value", "ping" => "pong" }, nil]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/2")

    # check the array returned by the amf
    assert_equal 4, result.size
    assert_equal 0, result[0], "Expected to get the status ok in the amf"
    assert_equal 0, result[1], "The old id should be 0"
    assert result[2] > 0, "The new id should be greater than 0"
    assert_equal 1, result[3], "The new version should be 1"
    
    # Finally check that the node that was saved has saved the data correctly 
    # in both the current and history tables
    # First check the current table
    current_node = Node.find(result[2])
    assert_in_delta lat, current_node.lat, 0.00001, "The latitude was not retreieved correctly"
    assert_in_delta lon, current_node.lon, 0.00001, "The longitude was not retreived correctly"
    assert_equal 2, current_node.tags.size, "There seems to be a tag that has been added to the node"
    assert_equal({ "key" => "value", "ping" => "pong" }, current_node.tags, "tags are different")
    assert_equal result[3], current_node.version, "The version returned, is different to the one returned by the amf"
    # Now check the history table
    historic_nodes = Node.find(:all, :conditions => { :id => result[2] })
    assert_equal 1, historic_nodes.size, "There should only be one historic node created"
    first_historic_node = historic_nodes.first
    assert_in_delta lat, first_historic_node.lat, 0.00001, "The latitude was not retreived correctly"
    assert_in_delta lon, first_historic_node.lon, 0.00001, "The longitude was not retreuved correctly"
    assert_equal 2, first_historic_node.tags.size, "There seems to be a tag that have been attached to this node"
    assert_equal({ "key" => "value", "ping" => "pong" }, first_historic_node.tags, "tags are different")
    assert_equal result[3], first_historic_node.version, "The version returned, is different to the one returned by the amf"

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
    if @response.body.class.to_s == 'Proc'
      res = StringIO.new()
      @response.body.call @response, res
      req = StringIO.new(res.string)
    else
      req = StringIO.new(@response.body)
    end
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
end
