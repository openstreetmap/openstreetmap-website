require "test_helper"
require "stringio"

class AmfControllerTest < ActionController::TestCase
  include Potlatch

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

  def test_getpresets
    user_en_de = create(:user, :languages => %w[en de])
    user_de = create(:user, :languages => %w[de])
    [user_en_de, user_de].each do |user|
      amf_content "getpresets", "/1", ["#{user.email}:test", ""]
      post :amf_read
      assert_response :success
      amf_parse_response
      presets = amf_result("/1")

      assert_equal 15, presets.length
      assert_equal POTLATCH_PRESETS[0], presets[0]
      assert_equal POTLATCH_PRESETS[1], presets[1]
      assert_equal POTLATCH_PRESETS[2], presets[2]
      assert_equal POTLATCH_PRESETS[3], presets[3]
      assert_equal POTLATCH_PRESETS[4], presets[4]
      assert_equal POTLATCH_PRESETS[5], presets[5]
      assert_equal POTLATCH_PRESETS[6], presets[6]
      assert_equal POTLATCH_PRESETS[7], presets[7]
      assert_equal POTLATCH_PRESETS[8], presets[8]
      assert_equal POTLATCH_PRESETS[9], presets[9]
      assert_equal POTLATCH_PRESETS[10], presets[10]
      assert_equal POTLATCH_PRESETS[12], presets[12]
      assert_equal user.languages.first, presets[13]["__potlatch_locale"]
    end
  end

  def test_getway
    # check a visible way
    way = create(:way_with_nodes, :nodes_count => 1)
    node = way.nodes.first
    user = way.changeset.user

    amf_content "getway", "/1", [way.id]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal way.id, result[2]
    assert_equal 1, result[3].length
    assert_equal node.id, result[3][0][2]
    assert_equal way.version, result[5]
    assert_equal user.id, result[6]
  end

  def test_getway_invisible
    # check an invisible way
    id = create(:way, :deleted).id

    amf_content "getway", "/1", [id]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    assert_equal(-4, result[0])
    assert_equal "way", result[1]
    assert_equal id, result[2]
    assert(result[3].nil? && result[4].nil? && result[5].nil? && result[6].nil?)
  end

  def test_getway_with_versions
    # check a way with multiple versions
    way = create(:way, :with_history, :version => 4)
    create(:way_node, :way => way)
    node = way.nodes.first
    user = way.changeset.user

    amf_content "getway", "/1", [way.id]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal way.id, result[2]
    assert_equal 1, result[3].length
    assert_equal node.id, result[3][0][2]
    assert_equal way.version, result[5]
    assert_equal user.id, result[6]
  end

  def test_getway_with_duplicate_nodes
    # check a way with duplicate nodes
    way = create(:way)
    node = create(:node)
    create(:way_node, :way => way, :node => node, :sequence_id => 1)
    create(:way_node, :way => way, :node => node, :sequence_id => 2)
    user = way.changeset.user

    amf_content "getway", "/1", [way.id]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal way.id, result[2]
    assert_equal 2, result[3].length
    assert_equal node.id, result[3][0][2]
    assert_equal node.id, result[3][1][2]
    assert_equal way.version, result[5]
    assert_equal user.id, result[6]
  end

  def test_getway_with_multiple_nodes
    # check a way with multiple nodes
    way = create(:way_with_nodes, :nodes_count => 3)
    a = way.nodes[0].id
    b = way.nodes[1].id
    c = way.nodes[2].id
    user = way.changeset.user

    amf_content "getway", "/1", [way.id]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal way.id, result[2]
    assert_equal 3, result[3].length
    assert_equal a, result[3][0][2]
    assert_equal b, result[3][1][2]
    assert_equal c, result[3][2][2]
    assert_equal way.version, result[5]
    assert_equal user.id, result[6]
  end

  def test_getway_nonexistent
    # check chat a non-existent way is not returned
    amf_content "getway", "/1", [0]
    post :amf_read
    assert_response :success
    amf_parse_response
    way = amf_result("/1")
    assert_equal(-4, way[0])
    assert_equal "way", way[1]
    assert_equal 0, way[2]
    assert(way[3].nil?) && way[4].nil? && way[5].nil? && way[6].nil?
  end

  def test_whichways
    node = create(:node, :lat => 3.0, :lon => 3.0)
    way = create(:way)
    deleted_way = create(:way, :deleted)
    create(:way_node, :way => way, :node => node)
    create(:way_node, :way => deleted_way, :node => node)
    create(:way_tag, :way => way)

    minlon = node.lon - 0.1
    minlat = node.lat - 0.1
    maxlon = node.lon + 0.1
    maxlat = node.lat + 0.1
    amf_content "whichways", "/1", [minlon, minlat, maxlon, maxlat]
    post :amf_read
    assert_response :success
    amf_parse_response

    # check contents of message
    map = amf_result "/1"
    assert_equal 0, map[0], "map error code should be 0"
    assert_equal "", map[1], "map error text should be empty"

    # check the formatting of the message
    assert_equal 5, map.length, "map should have length 5"
    assert_equal Array, map[2].class, 'map "ways" element should be an array'
    assert_equal Array, map[3].class, 'map "nodes" element should be an array'
    assert_equal Array, map[4].class, 'map "relations" element should be an array'
    map[2].each do |w|
      assert_equal 2, w.length, "way should be (id, version) pair"
      assert w[0] == w[0].floor, "way ID should be an integer"
      assert w[1] == w[1].floor, "way version should be an integer"
    end

    map[3].each do |n|
      assert_equal 5, w.length, "node should be (id, lat, lon, [tags], version) tuple"
      assert n[0] == n[0].floor, "node ID should be an integer"
      assert n[1] >= minlat - 0.01, "node lat should be greater than min"
      assert n[1] <= maxlat - 0.01, "node lat should be less than max"
      assert n[2] >= minlon - 0.01, "node lon should be greater than min"
      assert n[2] <= maxlon - 0.01, "node lon should be less than max"
      assert_equal Array, a[3].class, "node tags should be array"
      assert n[4] == n[4].floor, "node version should be an integer"
    end

    map[4].each do |r|
      assert_equal 2, r.length, "relation should be (id, version) pair"
      assert r[0] == r[0].floor, "relation ID should be an integer"
      assert r[1] == r[1].floor, "relation version should be an integer"
    end

    # TODO: looks like amf_controller changed since this test was written
    # so someone who knows what they're doing should check this!
    ways = map[2].collect { |x| x[0] }
    assert ways.include?(way.id),
           "map should include used way"
    assert_not ways.include?(deleted_way.id),
               "map should not include deleted way"
  end

  ##
  # checks that too-large a bounding box will not be served.
  def test_whichways_toobig
    bbox = [-0.1, -0.1, 1.1, 1.1]
    check_bboxes_are_bad [bbox] do |map, _bbox|
      assert_boundary_error map, " The server said: The maximum bbox size is 0.25, and your request was too large. Either request a smaller area, or use planet.osm"
    end
  end

  ##
  # checks that an invalid bounding box will not be served. in this case
  # one with max < min latitudes.
  #
  # NOTE: the controller expands the bbox by 0.01 in each direction!
  def test_whichways_badlat
    bboxes = [[0, 0.1, 0.1, 0], [-0.1, 80, 0.1, 70], [0.24, 54.35, 0.25, 54.33]]
    check_bboxes_are_bad bboxes do |map, bbox|
      assert_boundary_error map, " The server said: The minimum latitude must be less than the maximum latitude, but it wasn't", bbox.inspect
    end
  end

  ##
  # same as test_whichways_badlat, but for longitudes
  #
  # NOTE: the controller expands the bbox by 0.01 in each direction!
  def test_whichways_badlon
    bboxes = [[80, -0.1, 70, 0.1], [54.35, 0.24, 54.33, 0.25]]
    check_bboxes_are_bad bboxes do |map, bbox|
      assert_boundary_error map, " The server said: The minimum longitude must be less than the maximum longitude, but it wasn't", bbox.inspect
    end
  end

  def test_whichways_deleted
    node = create(:node, :with_history, :lat => 24.0, :lon => 24.0)
    way = create(:way, :with_history)
    way_v1 = way.old_ways.find_by(:version => 1)
    deleted_way = create(:way, :with_history, :deleted)
    deleted_way_v1 = deleted_way.old_ways.find_by(:version => 1)
    create(:way_node, :way => way, :node => node)
    create(:way_node, :way => deleted_way, :node => node)
    create(:old_way_node, :old_way => way_v1, :node => node)
    create(:old_way_node, :old_way => deleted_way_v1, :node => node)

    minlon = node.lon - 0.1
    minlat = node.lat - 0.1
    maxlon = node.lon + 0.1
    maxlat = node.lat + 0.1
    amf_content "whichways_deleted", "/1", [minlon, minlat, maxlon, maxlat]
    post :amf_read
    assert_response :success
    amf_parse_response

    # check contents of message
    map = amf_result "/1"
    assert_equal 0, map[0], "first map element should be 0"
    assert_equal "", map[1], "second map element should be an empty string"
    assert_equal Array, map[2].class, "third map element should be an array"
    # TODO: looks like amf_controller changed since this test was written
    # so someone who knows what they're doing should check this!
    assert_not map[2].include?(way.id),
               "map should not include visible way"
    assert map[2].include?(deleted_way.id),
           "map should include deleted way"
  end

  def test_whichways_deleted_toobig
    bbox = [-0.1, -0.1, 1.1, 1.1]
    amf_content "whichways_deleted", "/1", bbox
    post :amf_read
    assert_response :success
    amf_parse_response

    map = amf_result "/1"
    assert_deleted_boundary_error map, " The server said: The maximum bbox size is 0.25, and your request was too large. Either request a smaller area, or use planet.osm"
  end

  def test_getrelation
    id = create(:relation).id
    amf_content "getrelation", "/1", [id]
    post :amf_read
    assert_response :success
    amf_parse_response
    rel = amf_result("/1")
    assert_equal rel[0], 0
    assert_equal rel[2], id
  end

  def test_getrelation_invisible
    id = create(:relation, :deleted).id
    amf_content "getrelation", "/1", [id]
    post :amf_read
    assert_response :success
    amf_parse_response
    rel = amf_result("/1")
    assert_equal rel[0], -4
    assert_equal rel[1], "relation"
    assert_equal rel[2], id
    assert(rel[3].nil?) && rel[4].nil?
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
    assert(rel[3].nil?) && rel[4].nil?
  end

  def test_getway_old
    latest = create(:way, :version => 2)
    v1 = create(:old_way, :current_way => latest, :version => 1, :timestamp => Time.now.utc - 2.minutes)
    _v2 = create(:old_way, :current_way => latest, :version => 2, :timestamp => Time.now.utc - 1.minute)

    # try to get the last visible version (specified by <0) (should be current version)
    # NOTE: looks from the API changes that this now expects a timestamp
    # instead of a version number...
    # try to get version 1
    { latest.id => "",
      v1.way_id => (v1.timestamp + 1).strftime("%d %b %Y, %H:%M:%S") }.each do |id, t|
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
    way_id = create(:way, :with_history, :version => 2).id
    { "foo"  => "bar",
      way_id => "not a date",
      way_id => "2009-03-25 00:00:00",                   # <- wrong format
      way_id => "0 Jan 2009 00:00:00",                   # <- invalid date
      -1     => "1 Jan 2009 00:00:00" }.each do |id, t|  # <- invalid
      amf_content "getway_old", "/1", [id, t]
      post :amf_read
      assert_response :success
      amf_parse_response
      returned_way = amf_result("/1")
      assert_equal(-1, returned_way[0])
      assert returned_way[3].nil?
      assert returned_way[4].nil?
      assert returned_way[5].nil?
    end
  end

  def test_getway_old_nonexistent
    # try to get the last version-10 (shoudn't exist)
    way = create(:way, :with_history, :version => 2)
    v1 = way.old_ways.find_by(:version => 1)
    # try to get last visible version of non-existent way
    # try to get specific version of non-existent way
    [[0, ""],
     [0, "1 Jan 1970, 00:00:00"],
     [v1.way_id, (v1.timestamp - 10).strftime("%d %b %Y, %H:%M:%S")]].each do |id, t|
      amf_content "getway_old", "/1", [id, t]
      post :amf_read
      assert_response :success
      amf_parse_response
      returned_way = amf_result("/1")
      assert_equal(-1, returned_way[0])
      assert returned_way[3].nil?
      assert returned_way[4].nil?
      assert returned_way[5].nil?
    end
  end

  def test_getway_old_invisible
    way = create(:way, :deleted, :with_history, :version => 1)
    v1 = way.old_ways.find_by(:version => 1)
    # try to get deleted version
    [[v1.way_id, (v1.timestamp + 10).strftime("%d %b %Y, %H:%M:%S")]].each do |id, t|
      amf_content "getway_old", "/1", [id, t]
      post :amf_read
      assert_response :success
      amf_parse_response
      returned_way = amf_result("/1")
      assert_equal(-1, returned_way[0])
      assert returned_way[3].nil?
      assert returned_way[4].nil?
      assert returned_way[5].nil?
    end
  end

  def test_getway_history
    latest = create(:way, :version => 2)
    oldest = create(:old_way, :current_way => latest, :version => 1, :timestamp => latest.timestamp - 2.minutes)
    create(:old_way, :current_way => latest, :version => 2, :timestamp => latest.timestamp)

    amf_content "getway_history", "/1", [latest.id]
    post :amf_read
    assert_response :success
    amf_parse_response
    history = amf_result("/1")

    # ['way',wayid,history]
    assert_equal "way", history[0]
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
    assert_equal history[0], "way"
    assert_equal history[1], 0
    assert history[2].empty?
  end

  def test_getnode_history
    node = create(:node, :version => 2)
    node_v1 = create(:old_node, :current_node => node, :version => 1, :timestamp => 3.days.ago)
    _node_v2 = create(:old_node, :current_node => node, :version => 2, :timestamp => 2.days.ago)
    node_v3 = create(:old_node, :current_node => node, :version => 3, :timestamp => 1.day.ago)

    amf_content "getnode_history", "/1", [node.id]
    post :amf_read
    assert_response :success
    amf_parse_response
    history = amf_result("/1")

    # ['node',nodeid,history]
    # note that (as per getway_history) we actually round up
    # to the next second
    assert_equal history[0], "node",
                 'first element should be "node"'
    assert_equal history[1], node.id,
                 "second element should be the input node ID"
    assert_equal history[2].first[0],
                 (node_v3.timestamp + 1).strftime("%d %b %Y, %H:%M:%S"),
                 "first element in third element (array) should be the latest version"
    assert_equal history[2].last[0],
                 (node_v1.timestamp + 1).strftime("%d %b %Y, %H:%M:%S"),
                 "last element in third element (array) should be the initial version"
  end

  def test_getnode_history_nonexistent
    amf_content "getnode_history", "/1", [0]
    post :amf_read
    assert_response :success
    amf_parse_response
    history = amf_result("/1")

    # ['node',nodeid,history]
    assert_equal history[0], "node"
    assert_equal history[1], 0
    assert history[2].empty?
  end

  def test_findgpx_bad_user
    amf_content "findgpx", "/1", [1, "test@example.com:wrong"]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 2, result.length
    assert_equal(-1, result[0])
    assert_match(/must be logged in/, result[1])

    blocked_user = create(:user)
    create(:user_block, :user => blocked_user)
    amf_content "findgpx", "/1", [1, "#{blocked_user.email}:test"]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 2, result.length
    assert_equal(-1, result[0])
    assert_match(/access to the API has been blocked/, result[1])
  end

  def test_findgpx_by_id
    user = create(:user)
    trace = create(:trace, :visibility => "private", :user => user)

    amf_content "findgpx", "/1", [trace.id, "#{user.email}:test"]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 3, result.length
    assert_equal 0, result[0]
    assert_equal "", result[1]
    traces = result[2]
    assert_equal 1, traces.length
    assert_equal 3, traces[0].length
    assert_equal trace.id, traces[0][0]
    assert_equal trace.name, traces[0][1]
    assert_equal trace.description, traces[0][2]
  end

  def test_findgpx_by_name
    user = create(:user)

    amf_content "findgpx", "/1", ["Trace", "#{user.email}:test"]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    # find by name fails as it uses mysql text search syntax...
    assert_equal 2, result.length
    assert_equal(-2, result[0])
  end

  def test_findrelations_by_id
    relation = create(:relation, :version => 4)

    amf_content "findrelations", "/1", [relation.id]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 1, result.length
    assert_equal 4, result[0].length
    assert_equal relation.id, result[0][0]
    assert_equal relation.tags, result[0][1]
    assert_equal relation.members, result[0][2]
    assert_equal relation.version, result[0][3]

    amf_content "findrelations", "/1", [999999]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 0, result.length
  end

  def test_findrelations_by_tags
    visible_relation = create(:relation)
    create(:relation_tag, :relation => visible_relation, :k => "test", :v => "yes")
    used_relation = create(:relation)
    super_relation = create(:relation)
    create(:relation_member, :relation => super_relation, :member => used_relation)
    create(:relation_tag, :relation => used_relation, :k => "test", :v => "yes")
    create(:relation_tag, :relation => used_relation, :k => "name", :v => "Test Relation")

    amf_content "findrelations", "/1", ["yes"]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1").sort

    assert_equal 2, result.length
    assert_equal 4, result[0].length
    assert_equal visible_relation.id, result[0][0]
    assert_equal visible_relation.tags, result[0][1]
    assert_equal visible_relation.members, result[0][2]
    assert_equal visible_relation.version, result[0][3]
    assert_equal 4, result[1].length
    assert_equal used_relation.id, result[1][0]
    assert_equal used_relation.tags, result[1][1]
    assert_equal used_relation.members, result[1][2]
    assert_equal used_relation.version, result[1][3]

    amf_content "findrelations", "/1", ["no"]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1").sort

    assert_equal 0, result.length
  end

  def test_getpoi_without_timestamp
    node = create(:node, :with_history, :version => 4)
    create(:node_tag, :node => node)

    amf_content "getpoi", "/1", [node.id, ""]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 7, result.length
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal node.id, result[2]
    assert_equal node.lon, result[3]
    assert_equal node.lat, result[4]
    assert_equal node.tags, result[5]
    assert_equal node.version, result[6]

    amf_content "getpoi", "/1", [999999, ""]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 3, result.length
    assert_equal(-4, result[0])
    assert_equal "node", result[1]
    assert_equal 999999, result[2]
  end

  def test_getpoi_with_timestamp
    current_node = create(:node, :with_history, :version => 4)
    node = current_node.old_nodes.find_by(:version => 2)

    # Timestamps are stored with microseconds, but xmlschema truncates them to
    # previous whole second, causing <= comparison to fail
    timestamp = (node.timestamp + 1.second).xmlschema

    amf_content "getpoi", "/1", [node.node_id, timestamp]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 7, result.length
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal node.node_id, result[2]
    assert_equal node.lon, result[3]
    assert_equal node.lat, result[4]
    assert_equal node.tags, result[5]
    assert_equal current_node.version, result[6]

    amf_content "getpoi", "/1", [node.node_id, "2000-01-01T00:00:00Z"]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 3, result.length
    assert_equal(-4, result[0])
    assert_equal "node", result[1]
    assert_equal node.node_id, result[2]

    amf_content "getpoi", "/1", [999999, Time.now.xmlschema]
    post :amf_read
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 3, result.length
    assert_equal(-4, result[0])
    assert_equal "node", result[1]
    assert_equal 999999, result[2]
  end

  # ************************************************************
  # AMF Write tests

  # check that we can update a poi
  def test_putpoi_update_valid
    nd = create(:node)
    cs_id = nd.changeset.id
    user = nd.changeset.user
    amf_content "putpoi", "/1", ["#{user.email}:test", cs_id, nd.version, nd.id, nd.lon, nd.lat, nd.tags, nd.visible]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 5, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal nd.id, result[2]
    assert_equal nd.id, result[3]
    assert_equal nd.version + 1, result[4]

    # Now try to update again, with a different lat/lon, using the updated version number
    lat = nd.lat + 0.1
    lon = nd.lon - 0.1
    amf_content "putpoi", "/2", ["#{user.email}:test", cs_id, nd.version + 1, nd.id, lon, lat, nd.tags, nd.visible]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/2")

    assert_equal 5, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal nd.id, result[2]
    assert_equal nd.id, result[3]
    assert_equal nd.version + 2, result[4]
  end

  # Check that we can create a no valid poi
  # Using similar method for the node controller test
  def test_putpoi_create_valid
    # This node has no tags

    # create a node with random lat/lon
    lat = rand(-50..49) + rand
    lon = rand(-50..49) + rand

    changeset = create(:changeset)
    user = changeset.user

    amf_content "putpoi", "/1", ["#{user.email}:test", changeset.id, nil, nil, lon, lat, {}, nil]
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
    historic_nodes = OldNode.where(:node_id => result[3])
    assert_equal 1, historic_nodes.size, "There should only be one historic node created"
    first_historic_node = historic_nodes.first
    assert_in_delta lat, first_historic_node.lat, 0.00001, "The latitude was not retreived correctly"
    assert_in_delta lon, first_historic_node.lon, 0.00001, "The longitude was not retreuved correctly"
    assert_equal 0, first_historic_node.tags.size, "There seems to be a tag that have been attached to this node"
    assert_equal result[4], first_historic_node.version, "The version returned, is different to the one returned by the amf"

    ####
    # This node has some tags

    # create a node with random lat/lon
    lat = rand(-50..49) + rand
    lon = rand(-50..49) + rand

    amf_content "putpoi", "/2", ["#{user.email}:test", changeset.id, nil, nil, lon, lat, { "key" => "value", "ping" => "pong" }, nil]
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
    historic_nodes = OldNode.where(:node_id => result[3])
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

    # create a node with random lat/lon
    lat = rand(-50..49) + rand
    lon = rand(-50..49) + rand

    changeset = create(:changeset)
    user = changeset.user

    mostly_invalid = (0..31).to_a.map(&:chr).join
    tags = { "something" => "foo#{mostly_invalid}bar" }

    amf_content "putpoi", "/1", ["#{user.email}:test", changeset.id, nil, nil, lon, lat, tags, nil]
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

    # create a node with random lat/lon
    lat = rand(-50..49) + rand
    lon = rand(-50..49) + rand

    changeset = create(:changeset)
    user = changeset.user

    invalid = "\xc0\xc0"
    tags = { "something" => "foo#{invalid}bar" }

    amf_content "putpoi", "/1", ["#{user.email}:test", changeset.id, nil, nil, lon, lat, tags, nil]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 2, result.size
    assert_equal(-1, result[0], "Expected to get the status FAIL in the amf")
    assert_equal "One of the tags is invalid. Linux users may need to upgrade to Flash Player 10.1.", result[1]
  end

  # try deleting a node
  def test_putpoi_delete_valid
    nd = create(:node)
    cs_id = nd.changeset.id
    user = nd.changeset.user

    amf_content "putpoi", "/1", ["#{user.email}:test", cs_id, nd.version, nd.id, nd.lon, nd.lat, nd.tags, false]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 5, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal nd.id, result[2]
    assert_equal nd.id, result[3]
    assert_equal nd.version + 1, result[4]

    current_node = Node.find(result[3].to_i)
    assert_equal false, current_node.visible
  end

  # try deleting a node that is already deleted
  def test_putpoi_delete_already_deleted
    nd = create(:node, :deleted)
    cs_id = nd.changeset.id
    user = nd.changeset.user

    amf_content "putpoi", "/1", ["#{user.email}:test", cs_id, nd.version, nd.id, nd.lon, nd.lat, nd.tags, false]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 3, result.size
    assert_equal(-4, result[0])
    assert_equal "node", result[1]
    assert_equal nd.id, result[2]
  end

  # try deleting a node that has never existed
  def test_putpoi_delete_not_found
    changeset = create(:changeset)
    cs_id = changeset.id
    user = changeset.user

    amf_content "putpoi", "/1", ["#{user.email}:test", cs_id, 1, 999999, 0, 0, {}, false]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 3, result.size
    assert_equal(-4, result[0])
    assert_equal "node", result[1]
    assert_equal 999999, result[2]
  end

  # try setting an invalid location on a node
  def test_putpoi_invalid_latlon
    nd = create(:node)
    cs_id = nd.changeset.id
    user = nd.changeset.user

    amf_content "putpoi", "/1", ["#{user.email}:test", cs_id, nd.version, nd.id, 200, 100, nd.tags, true]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 2, result.size
    assert_equal(-2, result[0])
    assert_match(/Node is not in the world/, result[1])
  end

  # check that we can create a way
  def test_putway_create_valid
    changeset = create(:changeset)
    cs_id = changeset.id
    user = changeset.user

    a = create(:node).id
    b = create(:node).id
    c = create(:node).id
    d = create(:node).id
    e = create(:node).id

    amf_content "putway", "/1", ["#{user.email}:test", cs_id, 0, -1, [a, b, c], { "test" => "new" }, [], {}]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    new_way_id = result[3].to_i

    assert_equal 8, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal(-1, result[2])
    assert_not_equal(-1, result[3])
    assert_equal({}, result[4])
    assert_equal 1, result[5]
    assert_equal({}, result[6])
    assert_equal({}, result[7])

    new_way = Way.find(new_way_id)
    assert_equal 1, new_way.version
    assert_equal [a, b, c], new_way.nds
    assert_equal({ "test" => "new" }, new_way.tags)

    amf_content "putway", "/1", ["#{user.email}:test", cs_id, 0, -1, [b, d, e, a], { "test" => "newer" }, [], {}]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    new_way_id = result[3].to_i

    assert_equal 8, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal(-1, result[2])
    assert_not_equal(-1, result[3])
    assert_equal({}, result[4])
    assert_equal 1, result[5]
    assert_equal({}, result[6])
    assert_equal({}, result[7])

    new_way = Way.find(new_way_id)
    assert_equal 1, new_way.version
    assert_equal [b, d, e, a], new_way.nds
    assert_equal({ "test" => "newer" }, new_way.tags)

    amf_content "putway", "/1", ["#{user.email}:test", cs_id, 0, -1, [b, -1, d, e], { "test" => "newest" }, [[4.56, 12.34, -1, 0, { "test" => "new" }], [12.34, 4.56, d, 1, { "test" => "ok" }]], { a => 1 }]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    new_way_id = result[3].to_i
    new_node_id = result[4]["-1"].to_i

    assert_equal 8, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal(-1, result[2])
    assert_not_equal(-1, result[3])
    assert_equal({ "-1" => new_node_id }, result[4])
    assert_equal 1, result[5]
    assert_equal({ new_node_id.to_s => 1, d.to_s => 2 }, result[6])
    assert_equal({ a.to_s => 1 }, result[7])

    new_way = Way.find(new_way_id)
    assert_equal 1, new_way.version
    assert_equal [b, new_node_id, d, e], new_way.nds
    assert_equal({ "test" => "newest" }, new_way.tags)

    new_node = Node.find(new_node_id)
    assert_equal 1, new_node.version
    assert_equal true, new_node.visible
    assert_equal 4.56, new_node.lon
    assert_equal 12.34, new_node.lat
    assert_equal({ "test" => "new" }, new_node.tags)

    changed_node = Node.find(d)
    assert_equal 2, changed_node.version
    assert_equal true, changed_node.visible
    assert_equal 12.34, changed_node.lon
    assert_equal 4.56, changed_node.lat
    assert_equal({ "test" => "ok" }, changed_node.tags)

    # node is not deleted because our other ways are using it
    deleted_node = Node.find(a)
    assert_equal 1, deleted_node.version
    assert_equal true, deleted_node.visible
  end

  # check that we can update a way
  def test_putway_update_valid
    way = create(:way_with_nodes, :nodes_count => 3)
    cs_id = way.changeset.id
    user = way.changeset.user

    assert_not_equal({ "test" => "ok" }, way.tags)
    amf_content "putway", "/1", ["#{user.email}:test", cs_id, way.version, way.id, way.nds, { "test" => "ok" }, [], {}]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 8, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal way.id, result[2]
    assert_equal way.id, result[3]
    assert_equal({}, result[4])
    assert_equal way.version + 1, result[5]
    assert_equal({}, result[6])
    assert_equal({}, result[7])

    new_way = Way.find(way.id)
    assert_equal way.version + 1, new_way.version
    assert_equal way.nds, new_way.nds
    assert_equal({ "test" => "ok" }, new_way.tags)

    # Test changing the nodes in the way
    a = create(:node).id
    b = create(:node).id
    c = create(:node).id
    d = create(:node).id

    assert_not_equal [a, b, c, d], way.nds
    amf_content "putway", "/1", ["#{user.email}:test", cs_id, way.version + 1, way.id, [a, b, c, d], way.tags, [], {}]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 8, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal way.id, result[2]
    assert_equal way.id, result[3]
    assert_equal({}, result[4])
    assert_equal way.version + 2, result[5]
    assert_equal({}, result[6])
    assert_equal({}, result[7])

    new_way = Way.find(way.id)
    assert_equal way.version + 2, new_way.version
    assert_equal [a, b, c, d], new_way.nds
    assert_equal way.tags, new_way.tags

    amf_content "putway", "/1", ["#{user.email}:test", cs_id, way.version + 2, way.id, [a, -1, b, c], way.tags, [[4.56, 12.34, -1, 0, { "test" => "new" }], [12.34, 4.56, b, 1, { "test" => "ok" }]], { d => 1 }]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    new_node_id = result[4]["-1"].to_i

    assert_equal 8, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal way.id, result[2]
    assert_equal way.id, result[3]
    assert_equal({ "-1" => new_node_id }, result[4])
    assert_equal way.version + 3, result[5]
    assert_equal({ new_node_id.to_s => 1, b.to_s => 2 }, result[6])
    assert_equal({ d.to_s => 1 }, result[7])

    new_way = Way.find(way.id)
    assert_equal way.version + 3, new_way.version
    assert_equal [a, new_node_id, b, c], new_way.nds
    assert_equal way.tags, new_way.tags

    new_node = Node.find(new_node_id)
    assert_equal 1, new_node.version
    assert_equal true, new_node.visible
    assert_equal 4.56, new_node.lon
    assert_equal 12.34, new_node.lat
    assert_equal({ "test" => "new" }, new_node.tags)

    changed_node = Node.find(b)
    assert_equal 2, changed_node.version
    assert_equal true, changed_node.visible
    assert_equal 12.34, changed_node.lon
    assert_equal 4.56, changed_node.lat
    assert_equal({ "test" => "ok" }, changed_node.tags)

    deleted_node = Node.find(d)
    assert_equal 2, deleted_node.version
    assert_equal false, deleted_node.visible
  end

  # check that we can delete a way
  def test_deleteway_valid
    way = create(:way_with_nodes, :nodes_count => 3)
    nodes = way.nodes.each_with_object({}) { |n, ns| ns[n.id] = n.version }
    cs_id = way.changeset.id
    user = way.changeset.user

    # Of the three nodes, two should be kept since they are used in
    # a different way, and the third deleted since it's unused

    a = way.nodes[0]
    create(:way_node, :node => a)
    b = way.nodes[1]
    create(:way_node, :node => b)
    c = way.nodes[2]

    amf_content "deleteway", "/1", ["#{user.email}:test", cs_id, way.id, way.version, nodes]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 5, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal way.id, result[2]
    assert_equal way.version + 1, result[3]
    assert_equal({ c.id.to_s => 2 }, result[4])

    new_way = Way.find(way.id)
    assert_equal way.version + 1, new_way.version
    assert_equal false, new_way.visible

    way.nds.each do |node_id|
      assert_equal result[4][node_id.to_s].nil?, Node.find(node_id).visible
    end
  end

  # check that we can't delete a way that is in use
  def test_deleteway_inuse
    way = create(:way_with_nodes, :nodes_count => 4)
    create(:relation_member, :member => way)
    nodes = way.nodes.each_with_object({}) { |n, ns| ns[n.id] = n.version }
    cs_id = way.changeset.id
    user = way.changeset.user

    amf_content "deleteway", "/1", ["#{user.email}:test", cs_id, way.id, way.version, nodes]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 2, result.size
    assert_equal(-1, result[0])
    assert_match(/Way #{way.id} is still used/, result[1])

    new_way = Way.find(way.id)
    assert_equal way.version, new_way.version
    assert_equal true, new_way.visible

    way.nds.each do |node_id|
      assert_equal true, Node.find(node_id).visible
    end
  end

  # check that we can create a relation
  def test_putrelation_create_valid
    changeset = create(:changeset)
    user = changeset.user
    cs_id = changeset.id

    node = create(:node)
    way = create(:way_with_nodes, :nodes_count => 2)
    relation = create(:relation)

    amf_content "putrelation", "/1", ["#{user.email}:test", cs_id, 0, -1, { "test" => "new" }, [["Node", node.id, "node"], ["Way", way.id, "way"], ["Relation", relation.id, "relation"]], true]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    new_relation_id = result[3].to_i

    assert_equal 5, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal(-1, result[2])
    assert_not_equal(-1, result[3])
    assert_equal 1, result[4]

    new_relation = Relation.find(new_relation_id)
    assert_equal 1, new_relation.version
    assert_equal [["Node", node.id, "node"], ["Way", way.id, "way"], ["Relation", relation.id, "relation"]], new_relation.members
    assert_equal({ "test" => "new" }, new_relation.tags)
    assert_equal true, new_relation.visible
  end

  # check that we can update a relation
  def test_putrelation_update_valid
    relation = create(:relation)
    create(:relation_member, :relation => relation)
    user = relation.changeset.user
    cs_id = relation.changeset.id

    assert_not_equal({ "test" => "ok" }, relation.tags)
    amf_content "putrelation", "/1", ["#{user.email}:test", cs_id, relation.version, relation.id, { "test" => "ok" }, relation.members, true]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 5, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal relation.id, result[2]
    assert_equal relation.id, result[3]
    assert_equal relation.version + 1, result[4]

    new_relation = Relation.find(relation.id)
    assert_equal relation.version + 1, new_relation.version
    assert_equal relation.members, new_relation.members
    assert_equal({ "test" => "ok" }, new_relation.tags)
    assert_equal true, new_relation.visible
  end

  # check that we can delete a relation
  def test_putrelation_delete_valid
    relation = create(:relation)
    create(:relation_member, :relation => relation)
    create(:relation_tag, :relation => relation)
    cs_id = relation.changeset.id
    user = relation.changeset.user

    amf_content "putrelation", "/1", ["#{user.email}:test", cs_id, relation.version, relation.id, relation.tags, relation.members, false]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 5, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_equal relation.id, result[2]
    assert_equal relation.id, result[3]
    assert_equal relation.version + 1, result[4]

    new_relation = Relation.find(relation.id)
    assert_equal relation.version + 1, new_relation.version
    assert_equal [], new_relation.members
    assert_equal({}, new_relation.tags)
    assert_equal false, new_relation.visible
  end

  # check that we can't delete a relation that is in use
  def test_putrelation_delete_inuse
    relation = create(:relation)
    super_relation = create(:relation)
    create(:relation_member, :relation => super_relation, :member => relation)
    cs_id = relation.changeset.id
    user = relation.changeset.user

    amf_content "putrelation", "/1", ["#{user.email}:test", cs_id, relation.version, relation.id, relation.tags, relation.members, false]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 2, result.size
    assert_equal(-1, result[0])
    assert_match(/relation #{relation.id} is used in/, result[1])

    new_relation = Relation.find(relation.id)
    assert_equal relation.version, new_relation.version
    assert_equal relation.members, new_relation.members
    assert_equal relation.tags, new_relation.tags
    assert_equal true, new_relation.visible
  end

  # check that we can open a changeset
  def test_startchangeset_valid
    user = create(:user)

    amf_content "startchangeset", "/1", ["#{user.email}:test", { "source" => "new" }, nil, "new", 1]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    new_cs_id = result[2].to_i

    assert_equal 3, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]

    cs = Changeset.find(new_cs_id)
    assert_equal true, cs.is_open?
    assert_equal({ "comment" => "new", "source" => "new" }, cs.tags)

    old_cs_id = new_cs_id

    amf_content "startchangeset", "/1", ["#{user.email}:test", { "source" => "newer" }, old_cs_id, "newer", 1]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    new_cs_id = result[2].to_i

    assert_not_equal old_cs_id, new_cs_id

    assert_equal 3, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]

    cs = Changeset.find(old_cs_id)
    assert_equal false, cs.is_open?
    assert_equal({ "comment" => "newer", "source" => "new" }, cs.tags)

    cs = Changeset.find(new_cs_id)
    assert_equal true, cs.is_open?
    assert_equal({ "comment" => "newer", "source" => "newer" }, cs.tags)

    old_cs_id = new_cs_id

    amf_content "startchangeset", "/1", ["#{user.email}:test", {}, old_cs_id, "", 0]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 3, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]
    assert_nil result[2]

    cs = Changeset.find(old_cs_id)
    assert_equal false, cs.is_open?
    assert_equal({ "comment" => "newer", "source" => "newer" }, cs.tags)
  end

  # check that we can't close somebody elses changeset
  def test_startchangeset_invalid_wrong_user
    user = create(:user)
    user2 = create(:user)

    amf_content "startchangeset", "/1", ["#{user.email}:test", { "source" => "new" }, nil, "new", 1]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    cs_id = result[2].to_i

    assert_equal 3, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]

    cs = Changeset.find(cs_id)
    assert_equal true, cs.is_open?
    assert_equal({ "comment" => "new", "source" => "new" }, cs.tags)

    amf_content "startchangeset", "/1", ["#{user2.email}:test", {}, cs_id, "delete", 0]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")

    assert_equal 2, result.size
    assert_equal(-2, result[0])
    assert_equal "The user doesn't own that changeset", result[1]

    cs = Changeset.find(cs_id)
    assert_equal true, cs.is_open?
    assert_equal({ "comment" => "new", "source" => "new" }, cs.tags)
  end

  # check that invalid characters are stripped from changeset tags
  def test_startchangeset_invalid_xmlchar_comment
    user = create(:user)

    invalid = "\035\022"
    comment = "foo#{invalid}bar"

    amf_content "startchangeset", "/1", ["#{user.email}:test", {}, nil, comment, 1]
    post :amf_write
    assert_response :success
    amf_parse_response
    result = amf_result("/1")
    new_cs_id = result[2].to_i

    assert_equal 3, result.size
    assert_equal 0, result[0]
    assert_equal "", result[1]

    cs = Changeset.find(new_cs_id)
    assert_equal true, cs.is_open?
    assert_equal({ "comment" => "foobar" }, cs.tags)
  end

  private

  # ************************************************************
  # AMF Helper functions

  # Get the result record for the specified ID
  # It's an assertion FAIL if the record does not exist
  def amf_result(ref)
    assert @amf_result.key?("#{ref}/onResult")
    @amf_result["#{ref}/onResult"]
  end

  # Encode the AMF message to invoke "target" with parameters as
  # the passed data. The ref is used to retrieve the results.
  def amf_content(target, ref, data)
    a, b = 1.divmod(256)
    c = StringIO.new
    c.write 0.chr + 0.chr   # version 0
    c.write 0.chr + 0.chr   # n headers
    c.write a.chr + b.chr   # n bodies
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

    req.read(2) # version

    # parse through any headers
    headers = AMF.getint(req)        # Read number of headers
    headers.times do                 # Read each header
      AMF.getstring(req)             #  |
      req.getc                       #  | skip boolean
      AMF.getvalue(req)              #  |
    end

    # parse through responses
    results = {}
    bodies = AMF.getint(req)         # Read number of bodies
    bodies.times do                  # Read each body
      message = AMF.getstring(req)   #  | get message name
      AMF.getstring(req)             #  | get index in response sequence
      AMF.getlong(req)               #  | get total size in bytes
      args = AMF.getvalue(req)       #  | get response (probably an array)
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
  def assert_boundary_error(map, msg = nil, error_hint = nil)
    expected_map = [-2, "Sorry - I can't get the map for that area.#{msg}"]
    assert_equal expected_map, map, "AMF controller should have returned an error. (#{error_hint})"
  end

  # this should be what AMF controller returns when the bbox of a
  # whichways_deleted request is invalid or too large.
  def assert_deleted_boundary_error(map, msg = nil, error_hint = nil)
    expected_map = [-2, "Sorry - I can't get the map for that area.#{msg}"]
    assert_equal expected_map, map, "AMF controller should have returned an error. (#{error_hint})"
  end
end
