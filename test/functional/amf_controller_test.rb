require File.dirname(__FILE__) + '/../test_helper'
require 'stringio'
include Potlatch

class AmfControllerTest < ActionController::TestCase
  api_fixtures

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
    assert map[0].include?(current_ways(:used_way).id)
    assert !map[0].include?(current_ways(:invisible_way).id)
  end

  def test_whichways_toobig
    bbox = [-0.1,-0.1,1.1,1.1]
    amf_content "whichways", "/1", bbox
    post :amf_read
    assert_response :success
    amf_parse_response 

    # FIXME: whichways needs to reject large bboxes and the test needs to check for this
    map = amf_result "/1"
    assert map[0].empty? and map[1].empty? and map[2].empty?
  end

  def test_whichways_badlat
    bboxes = [[0,0.1,0.1,0], [-0.1,80,0.1,70], [0.24,54.34,0.25,54.33]]
    bboxes.each do |bbox|
      amf_content "whichways", "/1", bbox
      post :amf_read
      assert_response :success
      amf_parse_response 

      # FIXME: whichways needs to reject bboxes with illegal lats and the test needs to check for this
      map = amf_result "/1"
      assert map[0].empty? and map[1].empty? and map[2].empty?
    end
  end

  def test_whichways_badlon
    bboxes = [[80,-0.1,70,0.1], [54.34,0.24,54.33,0.25]]
    bboxes.each do |bbox|
      amf_content "whichways", "/1", bbox
      post :amf_read
      assert_response :success
      amf_parse_response

      # FIXME: whichways needs to reject bboxes with illegal lons and the test needs to check for this
      map = amf_result "/1"
      assert map[0].empty? and map[1].empty? and map[2].empty?
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
    ways = amf_result "/1"
    assert ways[0].include?(current_ways(:invisible_way).id)
    assert !ways[0].include?(current_ways(:used_way).id)
  end

  def test_whichways_deleted_toobig
    bbox = [-0.1,-0.1,1.1,1.1]
    amf_content "whichways_deleted", "/1", bbox
    post :amf_read
    assert_response :success
    amf_parse_response 

    ways = amf_result "/1"
    assert ways[0].empty?
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

end
