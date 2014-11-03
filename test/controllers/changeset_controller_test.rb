require 'test_helper'
require 'changeset_controller'

class ChangesetControllerTest < ActionController::TestCase
  api_fixtures
  fixtures :changeset_comments, :changesets_subscribers

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/changeset/create", :method => :put },
      { :controller => "changeset", :action => "create" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1/upload", :method => :post },
      { :controller => "changeset", :action => "upload", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1/download", :method => :get },
      { :controller => "changeset", :action => "download", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1/expand_bbox", :method => :post },
      { :controller => "changeset", :action => "expand_bbox", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1", :method => :get },
      { :controller => "changeset", :action => "read", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1/subscribe", :method => :post },
      { :controller => "changeset", :action => "subscribe", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1/unsubscribe", :method => :post },
      { :controller => "changeset", :action => "unsubscribe", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1", :method => :put },
      { :controller => "changeset", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1/close", :method => :put },
      { :controller => "changeset", :action => "close", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1/comment", :method => :post },
      { :controller => "changeset", :action => "comment", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/comment/1/hide", :method => :post },
      { :controller => "changeset", :action => "hide_comment", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/comment/1/unhide", :method => :post },
      { :controller => "changeset", :action => "unhide_comment", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changesets", :method => :get },
      { :controller => "changeset", :action => "query" }
    )
    assert_routing(
      { :path => "/changeset/1/comments/feed", :method => :get },
      { :controller => "changeset", :action => "comments_feed", :id => "1", :format =>"rss" }
    )
    assert_routing(
      { :path => "/user/name/history", :method => :get },
      { :controller => "changeset", :action => "list", :display_name => "name" }
    )
    assert_routing(
      { :path => "/user/name/history/feed", :method => :get },
      { :controller => "changeset", :action => "feed", :display_name => "name", :format => :atom }
    )
    assert_routing(
      { :path => "/history/friends", :method => :get },
      { :controller => "changeset", :action => "list", :friends => true }
    )
    assert_routing(
      { :path => "/history/nearby", :method => :get },
      { :controller => "changeset", :action => "list", :nearby => true }
    )
    assert_routing(
      { :path => "/history", :method => :get },
      { :controller => "changeset", :action => "list" }
    )
    assert_routing(
      { :path => "/history/feed", :method => :get },
      { :controller => "changeset", :action => "feed", :format => :atom }
    )
    assert_routing(
      { :path => "/history/comments/feed", :method => :get },
      { :controller => "changeset", :action => "comments_feed", :format =>"rss" }
    )
  end

  # -----------------------
  # Test simple changeset creation
  # -----------------------

  def test_create
    basic_authorization users(:normal_user).email, "test"
    # Create the first user's changeset
    content "<osm><changeset>" +
      "<tag k='created_by' v='osm test suite checking changesets'/>" +
      "</changeset></osm>"
    put :create
    assert_require_public_data


    basic_authorization users(:public_user).email, "test"
    # Create the first user's changeset
    content "<osm><changeset>" +
      "<tag k='created_by' v='osm test suite checking changesets'/>" +
      "</changeset></osm>"
    put :create

    assert_response :success, "Creation of changeset did not return sucess status"
    newid = @response.body.to_i

    # check end time, should be an hour ahead of creation time
    cs = Changeset.find(newid)
    duration = cs.closed_at - cs.created_at
    # the difference can either be a rational, or a floating point number
    # of seconds, depending on the code path taken :-(
    if duration.class == Rational
      assert_equal Rational(1,24), duration , "initial idle timeout should be an hour (#{cs.created_at} -> #{cs.closed_at})"
    else
      # must be number of seconds...
      assert_equal 3600, duration.round, "initial idle timeout should be an hour (#{cs.created_at} -> #{cs.closed_at})"
    end

    # checks if uploader was subscribed
    assert_equal 1, cs.subscribers.length
  end

  def test_create_invalid
    basic_authorization users(:normal_user).email, "test"
    content "<osm><changeset></osm>"
    put :create
    assert_require_public_data

    ## Try the public user
    basic_authorization users(:public_user).email, "test"
    content "<osm><changeset></osm>"
    put :create
    assert_response :bad_request, "creating a invalid changeset should fail"
  end

  def test_create_invalid_no_content
    ## First check with no auth
    put :create
    assert_response :unauthorized, "shouldn't be able to create a changeset with no auth"

    ## Now try to with the non-public user
    basic_authorization users(:normal_user).email, "test"
    put :create
    assert_require_public_data

    ## Try the inactive user
    basic_authorization users(:inactive_user).email, "test"
    put :create
    assert_inactive_user

    ## Now try to use the public user
    basic_authorization users(:public_user).email, "test"
    put :create
    assert_response :bad_request, "creating a changeset with no content should fail"
  end

  def test_create_wrong_method
    basic_authorization users(:public_user).email, "test"
    get :create
    assert_response :method_not_allowed
    post :create
    assert_response :method_not_allowed
  end

  ##
  # check that the changeset can be read and returns the correct
  # document structure.
  def test_read
    changeset_id = changesets(:normal_user_first_change).id
    get :read, :id => changeset_id
    assert_response :success, "cannot get first changeset"

    assert_select "osm[version=#{API_VERSION}][generator=\"OpenStreetMap server\"]", 1
    assert_select "osm>changeset[id=#{changeset_id}]", 1
    assert_select "osm>changeset>discussion", 0

    get :read, :id => changeset_id, :include_discussion => true
    assert_response :success, "cannot get first changeset with comments"

    assert_select "osm[version=#{API_VERSION}][generator=\"OpenStreetMap server\"]", 1
    assert_select "osm>changeset[id=#{changeset_id}]", 1
    assert_select "osm>changeset>discussion", 1
  end

  ##
  # check that a changeset that doesn't exist returns an appropriate message
  def test_read_not_found
    [0, -32, 233455644, "afg", "213"].each do |id|
      begin
        get :read, :id => id
        assert_response :not_found, "should get a not found"
      rescue ActionController::UrlGenerationError => ex
        assert_match /No route matches/, ex.to_s
      end
    end
  end

  ##
  # test that the user who opened a change can close it
  def test_close
    ## Try without authentication
    put :close, :id => changesets(:public_user_first_change).id
    assert_response :unauthorized


    ## Try using the non-public user
    basic_authorization users(:normal_user).email, "test"
    put :close, :id => changesets(:normal_user_first_change).id
    assert_require_public_data


    ## The try with the public user
    basic_authorization users(:public_user).email, "test"

    cs_id = changesets(:public_user_first_change).id
    put :close, :id => cs_id
    assert_response :success

    # test that it really is closed now
    cs = Changeset.find(cs_id)
    assert(!cs.is_open?,
           "changeset should be closed now (#{cs.closed_at} > #{Time.now.getutc}.")
  end

  ##
  # test that a different user can't close another user's changeset
  def test_close_invalid
    basic_authorization users(:public_user).email, "test"

    put :close, :id => changesets(:normal_user_first_change).id
    assert_response :conflict
    assert_equal "The user doesn't own that changeset", @response.body
  end

  ##
  # test that you can't close using another method
  def test_close_method_invalid
    basic_authorization users(:public_user).email, "test"

    cs_id = changesets(:public_user_first_change).id
    get :close, :id => cs_id
    assert_response :method_not_allowed

    post :close, :id => cs_id
    assert_response :method_not_allowed
  end

  ##
  # check that you can't close a changeset that isn't found
  def test_close_not_found
    cs_ids = [0, -132, "123"]

    # First try to do it with no auth
    cs_ids.each do |id|
      begin
        put :close, :id => id
        assert_response :unauthorized, "Shouldn't be able close the non-existant changeset #{id}, when not authorized"
      rescue ActionController::UrlGenerationError => ex
        assert_match /No route matches/, ex.to_s
      end
    end

    # Now try with auth
    basic_authorization users(:public_user).email, "test"
    cs_ids.each do |id|
      begin
        put :close, :id => id
        assert_response :not_found, "The changeset #{id} doesn't exist, so can't be closed"
      rescue ActionController::UrlGenerationError => ex
        assert_match /No route matches/, ex.to_s
      end
    end
  end

  ##
  # upload something simple, but valid and check that it can
  # be read back ok
  # Also try without auth and another user.
  def test_upload_simple_valid
    ## Try with no auth
    changeset_id = changesets(:public_user_first_change).id

    # simple diff to change a node, way and relation by removing
    # their tags
    diff = <<EOF
<osmChange>
 <modify>
  <node id='1' lon='0' lat='0' changeset='#{changeset_id}' version='1'/>
  <way id='1' changeset='#{changeset_id}' version='1'>
   <nd ref='3'/>
  </way>
 </modify>
 <modify>
  <relation id='1' changeset='#{changeset_id}' version='1'>
   <member type='way' role='some' ref='3'/>
   <member type='node' role='some' ref='5'/>
   <member type='relation' role='some' ref='3'/>
  </relation>
 </modify>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => changeset_id
    assert_response :unauthorized,
      "shouldnn't be able to upload a simple valid diff to changeset: #{@response.body}"



    ## Now try with a private user
    basic_authorization users(:normal_user).email, "test"
    changeset_id = changesets(:normal_user_first_change).id

    # simple diff to change a node, way and relation by removing
    # their tags
    diff = <<EOF
<osmChange>
 <modify>
  <node id='1' lon='0' lat='0' changeset='#{changeset_id}' version='1'/>
  <way id='1' changeset='#{changeset_id}' version='1'>
   <nd ref='3'/>
  </way>
 </modify>
 <modify>
  <relation id='1' changeset='#{changeset_id}' version='1'>
   <member type='way' role='some' ref='3'/>
   <member type='node' role='some' ref='5'/>
   <member type='relation' role='some' ref='3'/>
  </relation>
 </modify>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => changeset_id
    assert_response :forbidden,
      "can't upload a simple valid diff to changeset: #{@response.body}"



    ## Now try with the public user
    basic_authorization users(:public_user).email, "test"
    changeset_id = changesets(:public_user_first_change).id

    # simple diff to change a node, way and relation by removing
    # their tags
    diff = <<EOF
<osmChange>
 <modify>
  <node id='1' lon='0' lat='0' changeset='#{changeset_id}' version='1'/>
  <way id='1' changeset='#{changeset_id}' version='1'>
   <nd ref='3'/>
  </way>
 </modify>
 <modify>
  <relation id='1' changeset='#{changeset_id}' version='1'>
   <member type='way' role='some' ref='3'/>
   <member type='node' role='some' ref='5'/>
   <member type='relation' role='some' ref='3'/>
  </relation>
 </modify>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => changeset_id
    assert_response :success,
      "can't upload a simple valid diff to changeset: #{@response.body}"

    # check that the changes made it into the database
    assert_equal 0, Node.find(1).tags.size, "node 1 should now have no tags"
    assert_equal 0, Way.find(1).tags.size, "way 1 should now have no tags"
    assert_equal 0, Relation.find(1).tags.size, "relation 1 should now have no tags"
  end

  ##
  # upload something which creates new objects using placeholders
  def test_upload_create_valid
    basic_authorization users(:public_user).email, "test"
    cs_id = changesets(:public_user_first_change).id

    # simple diff to create a node way and relation using placeholders
    diff = <<EOF
<osmChange>
 <create>
  <node id='-1' lon='0' lat='0' changeset='#{cs_id}'>
   <tag k='foo' v='bar'/>
   <tag k='baz' v='bat'/>
  </node>
  <way id='-1' changeset='#{cs_id}'>
   <nd ref='3'/>
  </way>
 </create>
 <create>
  <relation id='-1' changeset='#{cs_id}'>
   <member type='way' role='some' ref='3'/>
   <member type='node' role='some' ref='5'/>
   <member type='relation' role='some' ref='3'/>
  </relation>
 </create>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => cs_id
    assert_response :success,
      "can't upload a simple valid creation to changeset: #{@response.body}"

    # check the returned payload
    assert_select "diffResult[version=#{API_VERSION}][generator=\"OpenStreetMap server\"]", 1
    assert_select "diffResult>node", 1
    assert_select "diffresult>way", 1
    assert_select "diffResult>relation", 1

    # inspect the response to find out what the new element IDs are
    doc = XML::Parser.string(@response.body).parse
    new_node_id = doc.find("//diffResult/node").first["new_id"].to_i
    new_way_id = doc.find("//diffResult/way").first["new_id"].to_i
    new_rel_id = doc.find("//diffResult/relation").first["new_id"].to_i

    # check the old IDs are all present and negative one
    assert_equal -1, doc.find("//diffResult/node").first["old_id"].to_i
    assert_equal -1, doc.find("//diffResult/way").first["old_id"].to_i
    assert_equal -1, doc.find("//diffResult/relation").first["old_id"].to_i

    # check the versions are present and equal one
    assert_equal 1, doc.find("//diffResult/node").first["new_version"].to_i
    assert_equal 1, doc.find("//diffResult/way").first["new_version"].to_i
    assert_equal 1, doc.find("//diffResult/relation").first["new_version"].to_i

    # check that the changes made it into the database
    assert_equal 2, Node.find(new_node_id).tags.size, "new node should have two tags"
    assert_equal 0, Way.find(new_way_id).tags.size, "new way should have no tags"
    assert_equal 0, Relation.find(new_rel_id).tags.size, "new relation should have no tags"
  end

  ##
  # test a complex delete where we delete elements which rely on eachother
  # in the same transaction.
  def test_upload_delete
    basic_authorization users(:public_user).display_name, "test"

    diff = XML::Document.new
    diff.root = XML::Node.new "osmChange"
    delete = XML::Node.new "delete"
    diff.root << delete
    delete << current_relations(:visible_relation).to_xml_node
    delete << current_relations(:used_relation).to_xml_node
    delete << current_ways(:used_way).to_xml_node
    delete << current_nodes(:node_used_by_relationship).to_xml_node

    # update the changeset to one that this user owns
    changeset_id = changesets(:public_user_first_change).id
    ["node", "way", "relation"].each do |type|
      delete.find("//osmChange/delete/#{type}").each do |n|
        n['changeset'] = changeset_id.to_s
      end
    end

    # upload it
    content diff
    post :upload, :id => changeset_id
    assert_response :success,
      "can't upload a deletion diff to changeset: #{@response.body}"

    # check the response is well-formed
    assert_select "diffResult>node", 1
    assert_select "diffResult>way", 1
    assert_select "diffResult>relation", 2

    # check that everything was deleted
    assert_equal false, Node.find(current_nodes(:node_used_by_relationship).id).visible
    assert_equal false, Way.find(current_ways(:used_way).id).visible
    assert_equal false, Relation.find(current_relations(:visible_relation).id).visible
    assert_equal false, Relation.find(current_relations(:used_relation).id).visible
  end

  ##
  # test uploading a delete with no lat/lon, as they are optional in
  # the osmChange spec.
  def test_upload_nolatlon_delete
    basic_authorization users(:public_user).display_name, "test"

    node = current_nodes(:public_visible_node)
    cs = changesets(:public_user_first_change)
    diff = "<osmChange><delete><node id='#{node.id}' version='#{node.version}' changeset='#{cs.id}'/></delete></osmChange>"

    # upload it
    content diff
    post :upload, :id => cs.id
    assert_response :success,
      "can't upload a deletion diff to changeset: #{@response.body}"

    # check the response is well-formed
    assert_select "diffResult>node", 1

    # check that everything was deleted
    assert_equal false, Node.find(node.id).visible
  end

  def test_repeated_changeset_create
    30.times do
      basic_authorization users(:public_user).email, "test"

      # create a temporary changeset
      content "<osm><changeset>" +
        "<tag k='created_by' v='osm test suite checking changesets'/>" +
        "</changeset></osm>"
      assert_difference('Changeset.count', 1) do
        put :create
      end
      assert_response :success
      changeset_id = @response.body.to_i
    end
  end

  def test_upload_large_changeset
    basic_authorization users(:public_user).email, "test"

    # create a changeset
    content "<osm><changeset/></osm>"
    put :create
    assert_response :success, "Should be able to create a changeset: #{@response.body}"
    changeset_id = @response.body.to_i

    # upload some widely-spaced nodes, spiralling positive and negative to cause
    # largest bbox over-expansion possible.
    diff = <<EOF
<osmChange>
 <create>
  <node id='-1' lon='-20' lat='-10' changeset='#{changeset_id}'/>
  <node id='-10' lon='20'  lat='10' changeset='#{changeset_id}'/>
  <node id='-2' lon='-40' lat='-20' changeset='#{changeset_id}'/>
  <node id='-11' lon='40'  lat='20' changeset='#{changeset_id}'/>
  <node id='-3' lon='-60' lat='-30' changeset='#{changeset_id}'/>
  <node id='-12' lon='60'  lat='30' changeset='#{changeset_id}'/>
  <node id='-4' lon='-80' lat='-40' changeset='#{changeset_id}'/>
  <node id='-13' lon='80'  lat='40' changeset='#{changeset_id}'/>
  <node id='-5' lon='-100' lat='-50' changeset='#{changeset_id}'/>
  <node id='-14' lon='100'  lat='50' changeset='#{changeset_id}'/>
  <node id='-6' lon='-120' lat='-60' changeset='#{changeset_id}'/>
  <node id='-15' lon='120'  lat='60' changeset='#{changeset_id}'/>
  <node id='-7' lon='-140' lat='-70' changeset='#{changeset_id}'/>
  <node id='-16' lon='140'  lat='70' changeset='#{changeset_id}'/>
  <node id='-8' lon='-160' lat='-80' changeset='#{changeset_id}'/>
  <node id='-17' lon='160'  lat='80' changeset='#{changeset_id}'/>
  <node id='-9' lon='-179.9' lat='-89.9' changeset='#{changeset_id}'/>
  <node id='-18' lon='179.9'  lat='89.9' changeset='#{changeset_id}'/>
 </create>
</osmChange>
EOF

    # upload it, which used to cause an error like "PGError: ERROR:
    # integer out of range" (bug #2152). but shouldn't any more.
    content diff
    post :upload, :id => changeset_id
    assert_response :success,
      "can't upload a spatially-large diff to changeset: #{@response.body}"

    # check that the changeset bbox is within bounds
    cs = Changeset.find(changeset_id)
    assert cs.min_lon >= -180 * GeoRecord::SCALE, "Minimum longitude (#{cs.min_lon / GeoRecord::SCALE}) should be >= -180 to be valid."
    assert cs.max_lon <=  180 * GeoRecord::SCALE, "Maximum longitude (#{cs.max_lon / GeoRecord::SCALE}) should be <= 180 to be valid."
    assert cs.min_lat >=  -90 * GeoRecord::SCALE, "Minimum latitude (#{cs.min_lat / GeoRecord::SCALE}) should be >= -90 to be valid."
    assert cs.max_lat >=   90 * GeoRecord::SCALE, "Maximum latitude (#{cs.max_lat / GeoRecord::SCALE}) should be <= 90 to be valid."
  end

  ##
  # test that deleting stuff in a transaction doesn't bypass the checks
  # to ensure that used elements are not deleted.
  def test_upload_delete_invalid
    basic_authorization users(:public_user).email, "test"

    diff = XML::Document.new
    diff.root = XML::Node.new "osmChange"
    delete = XML::Node.new "delete"
    diff.root << delete
    delete << current_relations(:public_visible_relation).to_xml_node
    delete << current_ways(:used_way).to_xml_node
    delete << current_nodes(:node_used_by_relationship).to_xml_node

    # upload it
    content diff
    post :upload, :id => 2
    assert_response :precondition_failed,
      "shouldn't be able to upload a invalid deletion diff: #{@response.body}"
    assert_equal "Precondition failed: Way 3 is still used by relations 1.", @response.body

    # check that nothing was, in fact, deleted
    assert_equal true, Node.find(current_nodes(:node_used_by_relationship).id).visible
    assert_equal true, Way.find(current_ways(:used_way).id).visible
    assert_equal true, Relation.find(current_relations(:visible_relation).id).visible
  end

  ##
  # test that a conditional delete of an in use object works.
  def test_upload_delete_if_unused
    basic_authorization users(:public_user).email, "test"

    diff = XML::Document.new
    diff.root = XML::Node.new "osmChange"
    delete = XML::Node.new "delete"
    diff.root << delete
    delete["if-unused"] = ""
    delete << current_relations(:public_used_relation).to_xml_node
    delete << current_ways(:used_way).to_xml_node
    delete << current_nodes(:node_used_by_relationship).to_xml_node

    # upload it
    content diff
    post :upload, :id => 2
    assert_response :success,
      "can't do a conditional delete of in use objects: #{@response.body}"

    # check the returned payload
    assert_select "diffResult[version=#{API_VERSION}][generator=\"OpenStreetMap server\"]", 1
    assert_select "diffResult>node", 1
    assert_select "diffresult>way", 1
    assert_select "diffResult>relation", 1

    # parse the response
    doc = XML::Parser.string(@response.body).parse

    # check the old IDs are all present and what we expect
    assert_equal current_nodes(:node_used_by_relationship).id, doc.find("//diffResult/node").first["old_id"].to_i
    assert_equal current_ways(:used_way).id, doc.find("//diffResult/way").first["old_id"].to_i
    assert_equal current_relations(:public_used_relation).id, doc.find("//diffResult/relation").first["old_id"].to_i

    # check the new IDs are all present and unchanged
    assert_equal current_nodes(:node_used_by_relationship).id, doc.find("//diffResult/node").first["new_id"].to_i
    assert_equal current_ways(:used_way).id, doc.find("//diffResult/way").first["new_id"].to_i
    assert_equal current_relations(:public_used_relation).id, doc.find("//diffResult/relation").first["new_id"].to_i

    # check the new versions are all present and unchanged
    assert_equal current_nodes(:node_used_by_relationship).version, doc.find("//diffResult/node").first["new_version"].to_i
    assert_equal current_ways(:used_way).version, doc.find("//diffResult/way").first["new_version"].to_i
    assert_equal current_relations(:public_used_relation).version, doc.find("//diffResult/relation").first["new_version"].to_i

    # check that nothing was, in fact, deleted
    assert_equal true, Node.find(current_nodes(:node_used_by_relationship).id).visible
    assert_equal true, Way.find(current_ways(:used_way).id).visible
    assert_equal true, Relation.find(current_relations(:public_used_relation).id).visible
  end

  ##
  # upload an element with a really long tag value
  def test_upload_invalid_too_long_tag
    basic_authorization users(:public_user).email, "test"
    cs_id = changesets(:public_user_first_change).id

    # simple diff to create a node way and relation using placeholders
    diff = <<EOF
<osmChange>
 <create>
  <node id='-1' lon='0' lat='0' changeset='#{cs_id}'>
   <tag k='foo' v='#{"x"*256}'/>
  </node>
 </create>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => cs_id
    assert_response :bad_request,
      "shoudln't be able to upload too long a tag to changeset: #{@response.body}"

  end

  ##
  # upload something which creates new objects and inserts them into
  # existing containers using placeholders.
  def test_upload_complex
    basic_authorization users(:public_user).email, "test"
    cs_id = changesets(:public_user_first_change).id

    # simple diff to create a node way and relation using placeholders
    diff = <<EOF
<osmChange>
 <create>
  <node id='-1' lon='0' lat='0' changeset='#{cs_id}'>
   <tag k='foo' v='bar'/>
   <tag k='baz' v='bat'/>
  </node>
 </create>
 <modify>
  <way id='1' changeset='#{cs_id}' version='1'>
   <nd ref='-1'/>
   <nd ref='3'/>
  </way>
  <relation id='1' changeset='#{cs_id}' version='1'>
   <member type='way' role='some' ref='3'/>
   <member type='node' role='some' ref='-1'/>
   <member type='relation' role='some' ref='3'/>
  </relation>
 </modify>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => cs_id
    assert_response :success,
      "can't upload a complex diff to changeset: #{@response.body}"

    # check the returned payload
    assert_select "diffResult[version=#{API_VERSION}][generator=\"#{GENERATOR}\"]", 1
    assert_select "diffResult>node", 1
    assert_select "diffResult>way", 1
    assert_select "diffResult>relation", 1

    # inspect the response to find out what the new element IDs are
    doc = XML::Parser.string(@response.body).parse
    new_node_id = doc.find("//diffResult/node").first["new_id"].to_i

    # check that the changes made it into the database
    assert_equal 2, Node.find(new_node_id).tags.size, "new node should have two tags"
    assert_equal [new_node_id, 3], Way.find(1).nds, "way nodes should match"
    Relation.find(1).members.each do |type,id,role|
      if type == 'node'
        assert_equal new_node_id, id, "relation should contain new node"
      end
    end
  end

  ##
  # create a diff which references several changesets, which should cause
  # a rollback and none of the diff gets committed
  def test_upload_invalid_changesets
    basic_authorization users(:public_user).email, "test"
    cs_id = changesets(:public_user_first_change).id

    # simple diff to create a node way and relation using placeholders
    diff = <<EOF
<osmChange>
 <modify>
  <node id='1' lon='0' lat='0' changeset='#{cs_id}' version='1'/>
  <way id='1' changeset='#{cs_id}' version='1'>
   <nd ref='3'/>
  </way>
 </modify>
 <modify>
  <relation id='1' changeset='#{cs_id}' version='1'>
   <member type='way' role='some' ref='3'/>
   <member type='node' role='some' ref='5'/>
   <member type='relation' role='some' ref='3'/>
  </relation>
 </modify>
 <create>
  <node id='-1' lon='0' lat='0' changeset='4'>
   <tag k='foo' v='bar'/>
   <tag k='baz' v='bat'/>
  </node>
 </create>
</osmChange>
EOF
    # cache the objects before uploading them
    node = current_nodes(:visible_node)
    way = current_ways(:visible_way)
    rel = current_relations(:visible_relation)

    # upload it
    content diff
    post :upload, :id => cs_id
    assert_response :conflict,
      "uploading a diff with multiple changsets should have failed"

    # check that objects are unmodified
    assert_nodes_are_equal(node, Node.find(1))
    assert_ways_are_equal(way, Way.find(1))
  end

  ##
  # upload multiple versions of the same element in the same diff.
  def test_upload_multiple_valid
    basic_authorization users(:public_user).email, "test"
    cs_id = changesets(:public_user_first_change).id

    # change the location of a node multiple times, each time referencing
    # the last version. doesn't this depend on version numbers being
    # sequential?
    diff = <<EOF
<osmChange>
 <modify>
  <node id='1' lon='0' lat='0' changeset='#{cs_id}' version='1'/>
  <node id='1' lon='1' lat='0' changeset='#{cs_id}' version='2'/>
  <node id='1' lon='1' lat='1' changeset='#{cs_id}' version='3'/>
  <node id='1' lon='1' lat='2' changeset='#{cs_id}' version='4'/>
  <node id='1' lon='2' lat='2' changeset='#{cs_id}' version='5'/>
  <node id='1' lon='3' lat='2' changeset='#{cs_id}' version='6'/>
  <node id='1' lon='3' lat='3' changeset='#{cs_id}' version='7'/>
  <node id='1' lon='9' lat='9' changeset='#{cs_id}' version='8'/>
 </modify>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => cs_id
    assert_response :success,
      "can't upload multiple versions of an element in a diff: #{@response.body}"

    # check the response is well-formed. its counter-intuitive, but the
    # API will return multiple elements with the same ID and different
    # version numbers for each change we made.
    assert_select "diffResult>node", 8
  end

  ##
  # upload multiple versions of the same element in the same diff, but
  # keep the version numbers the same.
  def test_upload_multiple_duplicate
    basic_authorization users(:public_user).email, "test"
    cs_id = changesets(:public_user_first_change).id

    diff = <<EOF
<osmChange>
 <modify>
  <node id='1' lon='0' lat='0' changeset='#{cs_id}' version='1'/>
  <node id='1' lon='1' lat='1' changeset='#{cs_id}' version='1'/>
 </modify>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => cs_id
    assert_response :conflict,
      "shouldn't be able to upload the same element twice in a diff: #{@response.body}"
  end

  ##
  # try to upload some elements without specifying the version
  def test_upload_missing_version
    basic_authorization users(:public_user).email, "test"
    cs_id = changesets(:public_user_first_change).id

    diff = <<EOF
<osmChange>
 <modify>
 <node id='1' lon='1' lat='1' changeset='cs_id'/>
 </modify>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => cs_id
    assert_response :bad_request,
      "shouldn't be able to upload an element without version: #{@response.body}"
  end

  ##
  # try to upload with commands other than create, modify, or delete
  def test_action_upload_invalid
    basic_authorization users(:public_user).email, "test"
    cs_id = changesets(:public_user_first_change).id

    diff = <<EOF
<osmChange>
  <ping>
   <node id='1' lon='1' lat='1' changeset='#{cs_id}' />
  </ping>
</osmChange>
EOF
  content diff
  post :upload, :id => cs_id
  assert_response :bad_request, "Shouldn't be able to upload a diff with the action ping"
  assert_equal @response.body, "Unknown action ping, choices are create, modify, delete"
  end

  ##
  # upload a valid changeset which has a mixture of whitespace
  # to check a bug reported by ivansanchez (#1565).
  def test_upload_whitespace_valid
    basic_authorization users(:public_user).email, "test"
    changeset_id = changesets(:public_user_first_change).id

    diff = <<EOF
<osmChange>
 <modify><node id='1' lon='0' lat='0' changeset='#{changeset_id}'
  version='1'></node>
  <node id='1' lon='1' lat='1' changeset='#{changeset_id}' version='2'><tag k='k' v='v'/></node></modify>
 <modify>
 <relation id='1' changeset='#{changeset_id}' version='1'><member
   type='way' role='some' ref='3'/><member
    type='node' role='some' ref='5'/>
   <member type='relation' role='some' ref='3'/>
  </relation>
 </modify></osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => changeset_id
    assert_response :success,
      "can't upload a valid diff with whitespace variations to changeset: #{@response.body}"

    # check the response is well-formed
    assert_select "diffResult>node", 2
    assert_select "diffResult>relation", 1

    # check that the changes made it into the database
    assert_equal 1, Node.find(1).tags.size, "node 1 should now have one tag"
    assert_equal 0, Relation.find(1).tags.size, "relation 1 should now have no tags"
  end

  ##
  # upload a valid changeset which has a mixture of whitespace
  # to check a bug reported by ivansanchez.
  def test_upload_reuse_placeholder_valid
    basic_authorization users(:public_user).email, "test"
    changeset_id = changesets(:public_user_first_change).id

    diff = <<EOF
<osmChange>
 <create>
  <node id='-1' lon='0' lat='0' changeset='#{changeset_id}'>
   <tag k="foo" v="bar"/>
  </node>
 </create>
 <modify>
  <node id='-1' lon='1' lat='1' changeset='#{changeset_id}' version='1'/>
 </modify>
 <delete>
  <node id='-1' lon='2' lat='2' changeset='#{changeset_id}' version='2'/>
 </delete>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => changeset_id
    assert_response :success,
      "can't upload a valid diff with re-used placeholders to changeset: #{@response.body}"

    # check the response is well-formed
    assert_select "diffResult>node", 3
    assert_select "diffResult>node[old_id=-1]", 3
  end

  ##
  # test what happens if a diff upload re-uses placeholder IDs in an
  # illegal way.
  def test_upload_placeholder_invalid
    basic_authorization users(:public_user).email, "test"
    changeset_id = changesets(:public_user_first_change).id

    diff = <<EOF
<osmChange>
 <create>
  <node id='-1' lon='0' lat='0' changeset='#{changeset_id}' version='1'/>
  <node id='-1' lon='1' lat='1' changeset='#{changeset_id}' version='1'/>
  <node id='-1' lon='2' lat='2' changeset='#{changeset_id}' version='2'/>
 </create>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => changeset_id
    assert_response :bad_request,
      "shouldn't be able to re-use placeholder IDs"
  end

  ##
  # test that uploading a way referencing invalid placeholders gives a
  # proper error, not a 500.
  def test_upload_placeholder_invalid_way
    basic_authorization users(:public_user).email, "test"
    changeset_id = changesets(:public_user_first_change).id

    diff = <<EOF
<osmChange>
 <create>
  <node id="-1" lon="0" lat="0" changeset="#{changeset_id}" version="1"/>
  <node id="-2" lon="1" lat="1" changeset="#{changeset_id}" version="1"/>
  <node id="-3" lon="2" lat="2" changeset="#{changeset_id}" version="1"/>
  <way id="-1" changeset="#{changeset_id}" version="1">
   <nd ref="-1"/>
   <nd ref="-2"/>
   <nd ref="-3"/>
   <nd ref="-4"/>
  </way>
 </create>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => changeset_id
    assert_response :bad_request,
      "shouldn't be able to use invalid placeholder IDs"
    assert_equal "Placeholder node not found for reference -4 in way -1", @response.body

    # the same again, but this time use an existing way
    diff = <<EOF
<osmChange>
 <create>
  <node id="-1" lon="0" lat="0" changeset="#{changeset_id}" version="1"/>
  <node id="-2" lon="1" lat="1" changeset="#{changeset_id}" version="1"/>
  <node id="-3" lon="2" lat="2" changeset="#{changeset_id}" version="1"/>
  <way id="1" changeset="#{changeset_id}" version="1">
   <nd ref="-1"/>
   <nd ref="-2"/>
   <nd ref="-3"/>
   <nd ref="-4"/>
  </way>
 </create>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => changeset_id
    assert_response :bad_request,
      "shouldn't be able to use invalid placeholder IDs"
    assert_equal "Placeholder node not found for reference -4 in way 1", @response.body
  end

  ##
  # test that uploading a relation referencing invalid placeholders gives a
  # proper error, not a 500.
  def test_upload_placeholder_invalid_relation
    basic_authorization users(:public_user).email, "test"
    changeset_id = changesets(:public_user_first_change).id

    diff = <<EOF
<osmChange>
 <create>
  <node id="-1" lon="0" lat="0" changeset="#{changeset_id}" version="1"/>
  <node id="-2" lon="1" lat="1" changeset="#{changeset_id}" version="1"/>
  <node id="-3" lon="2" lat="2" changeset="#{changeset_id}" version="1"/>
  <relation id="-1" changeset="#{changeset_id}" version="1">
   <member type="node" role="foo" ref="-1"/>
   <member type="node" role="foo" ref="-2"/>
   <member type="node" role="foo" ref="-3"/>
   <member type="node" role="foo" ref="-4"/>
  </relation>
 </create>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => changeset_id
    assert_response :bad_request,
      "shouldn't be able to use invalid placeholder IDs"
    assert_equal "Placeholder Node not found for reference -4 in relation -1.", @response.body

    # the same again, but this time use an existing way
    diff = <<EOF
<osmChange>
 <create>
  <node id="-1" lon="0" lat="0" changeset="#{changeset_id}" version="1"/>
  <node id="-2" lon="1" lat="1" changeset="#{changeset_id}" version="1"/>
  <node id="-3" lon="2" lat="2" changeset="#{changeset_id}" version="1"/>
  <relation id="1" changeset="#{changeset_id}" version="1">
   <member type="node" role="foo" ref="-1"/>
   <member type="node" role="foo" ref="-2"/>
   <member type="node" role="foo" ref="-3"/>
   <member type="way" role="bar" ref="-1"/>
  </relation>
 </create>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => changeset_id
    assert_response :bad_request,
      "shouldn't be able to use invalid placeholder IDs"
    assert_equal "Placeholder Way not found for reference -1 in relation 1.", @response.body
  end

  ##
  # test what happens if a diff is uploaded containing only a node
  # move.
  def test_upload_node_move
    basic_authorization users(:public_user).email, "test"

    content "<osm><changeset>" +
      "<tag k='created_by' v='osm test suite checking changesets'/>" +
      "</changeset></osm>"
    put :create
    assert_response :success
    changeset_id = @response.body.to_i

    old_node = current_nodes(:visible_node)

    diff = XML::Document.new
    diff.root = XML::Node.new "osmChange"
    modify = XML::Node.new "modify"
    xml_old_node = old_node.to_xml_node
    xml_old_node["lat"] = (2.0).to_s
    xml_old_node["lon"] = (2.0).to_s
    xml_old_node["changeset"] = changeset_id.to_s
    modify << xml_old_node
    diff.root << modify

    # upload it
    content diff
    post :upload, :id => changeset_id
    assert_response :success,
      "diff should have uploaded OK"

    # check the bbox
    changeset = Changeset.find(changeset_id)
    assert_equal 1*GeoRecord::SCALE, changeset.min_lon, "min_lon should be 1 degree"
    assert_equal 2*GeoRecord::SCALE, changeset.max_lon, "max_lon should be 2 degrees"
    assert_equal 1*GeoRecord::SCALE, changeset.min_lat, "min_lat should be 1 degree"
    assert_equal 2*GeoRecord::SCALE, changeset.max_lat, "max_lat should be 2 degrees"
  end

  ##
  # test what happens if a diff is uploaded adding a node to a way.
  def test_upload_way_extend
    basic_authorization users(:public_user).email, "test"

    content "<osm><changeset>" +
      "<tag k='created_by' v='osm test suite checking changesets'/>" +
      "</changeset></osm>"
    put :create
    assert_response :success
    changeset_id = @response.body.to_i

    old_way = current_ways(:visible_way)

    diff = XML::Document.new
    diff.root = XML::Node.new "osmChange"
    modify = XML::Node.new "modify"
    xml_old_way = old_way.to_xml_node
    nd_ref = XML::Node.new "nd"
    nd_ref["ref"] = current_nodes(:visible_node).id.to_s
    xml_old_way << nd_ref
    xml_old_way["changeset"] = changeset_id.to_s
    modify << xml_old_way
    diff.root << modify

    # upload it
    content diff
    post :upload, :id => changeset_id
    assert_response :success,
      "diff should have uploaded OK"

    # check the bbox
    changeset = Changeset.find(changeset_id)
    assert_equal 1*GeoRecord::SCALE, changeset.min_lon, "min_lon should be 1 degree"
    assert_equal 3*GeoRecord::SCALE, changeset.max_lon, "max_lon should be 3 degrees"
    assert_equal 1*GeoRecord::SCALE, changeset.min_lat, "min_lat should be 1 degree"
    assert_equal 3*GeoRecord::SCALE, changeset.max_lat, "max_lat should be 3 degrees"
  end

  ##
  # test for more issues in #1568
  def test_upload_empty_invalid
    basic_authorization users(:public_user).email, "test"

    [ "<osmChange/>",
      "<osmChange></osmChange>",
      "<osmChange><modify/></osmChange>",
      "<osmChange><modify></modify></osmChange>"
    ].each do |diff|
      # upload it
      content diff
      post :upload, :id => changesets(:public_user_first_change).id
      assert_response(:success, "should be able to upload " +
                      "empty changeset: " + diff)
    end
  end

  ##
  # test that the X-Error-Format header works to request XML errors
  def test_upload_xml_errors
    basic_authorization users(:public_user).email, "test"

    # try and delete a node that is in use
    diff = XML::Document.new
    diff.root = XML::Node.new "osmChange"
    delete = XML::Node.new "delete"
    diff.root << delete
    delete << current_nodes(:node_used_by_relationship).to_xml_node

    # upload it
    content diff
    error_format "xml"
    post :upload, :id => 2
    assert_response :success,
      "failed to return error in XML format"

    # check the returned payload
    assert_select "osmError[version=#{API_VERSION}][generator=\"OpenStreetMap server\"]", 1
    assert_select "osmError>status", 1
    assert_select "osmError>message", 1

  end

  ##
  # when we make some simple changes we get the same changes back from the
  # diff download.
  def test_diff_download_simple
    ## First try with the normal user, which should get a forbidden
    basic_authorization(users(:normal_user).email, "test")

    # create a temporary changeset
    content "<osm><changeset>" +
      "<tag k='created_by' v='osm test suite checking changesets'/>" +
      "</changeset></osm>"
    put :create
    assert_response :forbidden



    ## Now try with the public user
    basic_authorization(users(:public_user).email, "test")

    # create a temporary changeset
    content "<osm><changeset>" +
      "<tag k='created_by' v='osm test suite checking changesets'/>" +
      "</changeset></osm>"
    put :create
    assert_response :success
    changeset_id = @response.body.to_i

    # add a diff to it
    diff = <<EOF
<osmChange>
 <modify>
  <node id='1' lon='0' lat='0' changeset='#{changeset_id}' version='1'/>
  <node id='1' lon='1' lat='0' changeset='#{changeset_id}' version='2'/>
  <node id='1' lon='1' lat='1' changeset='#{changeset_id}' version='3'/>
  <node id='1' lon='1' lat='2' changeset='#{changeset_id}' version='4'/>
  <node id='1' lon='2' lat='2' changeset='#{changeset_id}' version='5'/>
  <node id='1' lon='3' lat='2' changeset='#{changeset_id}' version='6'/>
  <node id='1' lon='3' lat='3' changeset='#{changeset_id}' version='7'/>
  <node id='1' lon='9' lat='9' changeset='#{changeset_id}' version='8'/>
 </modify>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => changeset_id
    assert_response :success,
      "can't upload multiple versions of an element in a diff: #{@response.body}"

    get :download, :id => changeset_id
    assert_response :success

    assert_select "osmChange", 1
    assert_select "osmChange>modify", 8
    assert_select "osmChange>modify>node", 8
  end

  ##
  # culled this from josm to ensure that nothing in the way that josm
  # is formatting the request is causing it to fail.
  #
  # NOTE: the error turned out to be something else completely!
  def test_josm_upload
    basic_authorization(users(:public_user).email, "test")

    # create a temporary changeset
    content "<osm><changeset>" +
      "<tag k='created_by' v='osm test suite checking changesets'/>" +
      "</changeset></osm>"
    put :create
    assert_response :success
    changeset_id = @response.body.to_i

    diff = <<OSMFILE
<osmChange version="0.6" generator="JOSM">
<create version="0.6" generator="JOSM">
  <node id='-1' visible='true' changeset='#{changeset_id}' lat='51.49619982187321' lon='-0.18722061869438314' />
  <node id='-2' visible='true' changeset='#{changeset_id}' lat='51.496359883909605' lon='-0.18653093576241928' />
  <node id='-3' visible='true' changeset='#{changeset_id}' lat='51.49598132358285' lon='-0.18719613290981638' />
  <node id='-4' visible='true' changeset='#{changeset_id}' lat='51.4961591711078' lon='-0.18629015888084607' />
  <node id='-5' visible='true' changeset='#{changeset_id}' lat='51.49582126021711' lon='-0.18708186591517145' />
  <node id='-6' visible='true' changeset='#{changeset_id}' lat='51.49591018437858' lon='-0.1861432441734455' />
  <node id='-7' visible='true' changeset='#{changeset_id}' lat='51.49560784152179' lon='-0.18694719410005425' />
  <node id='-8' visible='true' changeset='#{changeset_id}' lat='51.49567389979617' lon='-0.1860289771788006' />
  <node id='-9' visible='true' changeset='#{changeset_id}' lat='51.49543761398892' lon='-0.186820684213126' />
  <way id='-10' action='modiy' visible='true' changeset='#{changeset_id}'>
    <nd ref='-1' />
    <nd ref='-2' />
    <nd ref='-3' />
    <nd ref='-4' />
    <nd ref='-5' />
    <nd ref='-6' />
    <nd ref='-7' />
    <nd ref='-8' />
    <nd ref='-9' />
    <tag k='highway' v='residential' />
    <tag k='name' v='Foobar Street' />
  </way>
</create>
</osmChange>
OSMFILE

    # upload it
    content diff
    post :upload, :id => changeset_id
    assert_response :success,
      "can't upload a diff from JOSM: #{@response.body}"

    get :download, :id => changeset_id
    assert_response :success

    assert_select "osmChange", 1
    assert_select "osmChange>create>node", 9
    assert_select "osmChange>create>way", 1
    assert_select "osmChange>create>way>nd", 9
    assert_select "osmChange>create>way>tag", 2
  end

  ##
  # when we make some complex changes we get the same changes back from the
  # diff download.
  def test_diff_download_complex
    basic_authorization(users(:public_user).email, "test")

    # create a temporary changeset
    content "<osm><changeset>" +
      "<tag k='created_by' v='osm test suite checking changesets'/>" +
      "</changeset></osm>"
    put :create
    assert_response :success
    changeset_id = @response.body.to_i

    # add a diff to it
    diff = <<EOF
<osmChange>
 <delete>
  <node id='1' lon='0' lat='0' changeset='#{changeset_id}' version='1'/>
 </delete>
 <create>
  <node id='-1' lon='9' lat='9' changeset='#{changeset_id}' version='0'/>
  <node id='-2' lon='8' lat='9' changeset='#{changeset_id}' version='0'/>
  <node id='-3' lon='7' lat='9' changeset='#{changeset_id}' version='0'/>
 </create>
 <modify>
  <node id='3' lon='20' lat='15' changeset='#{changeset_id}' version='1'/>
  <way id='1' changeset='#{changeset_id}' version='1'>
   <nd ref='3'/>
   <nd ref='-1'/>
   <nd ref='-2'/>
   <nd ref='-3'/>
  </way>
 </modify>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => changeset_id
    assert_response :success,
      "can't upload multiple versions of an element in a diff: #{@response.body}"

    get :download, :id => changeset_id
    assert_response :success

    assert_select "osmChange", 1
    assert_select "osmChange>create", 3
    assert_select "osmChange>delete", 1
    assert_select "osmChange>modify", 2
    assert_select "osmChange>create>node", 3
    assert_select "osmChange>delete>node", 1
    assert_select "osmChange>modify>node", 1
    assert_select "osmChange>modify>way", 1
  end

  def test_changeset_download
    get :download, :id => changesets(:normal_user_first_change).id
    assert_response :success
    assert_template nil
    #print @response.body
    # FIXME needs more assert_select tests
    assert_select "osmChange[version='#{API_VERSION}'][generator='#{GENERATOR}']" do
      assert_select "create", :count => 5
      assert_select "create>node[id=#{nodes(:used_node_2).node_id}][visible=#{nodes(:used_node_2).visible?}][version=#{nodes(:used_node_2).version}]" do
        assert_select "tag[k=#{node_tags(:t3).k}][v=#{node_tags(:t3).v}]"
      end
      assert_select "create>node[id=#{nodes(:visible_node).node_id}]"
    end
  end

  ##
  # check that the bounding box of a changeset gets updated correctly
  ## FIXME: This should really be moded to a integration test due to the with_controller
  def test_changeset_bbox
    basic_authorization users(:public_user).email, "test"

    # create a new changeset
    content "<osm><changeset/></osm>"
    put :create
    assert_response :success, "Creating of changeset failed."
    changeset_id = @response.body.to_i

    # add a single node to it
    with_controller(NodeController.new) do
      content "<osm><node lon='1' lat='2' changeset='#{changeset_id}'/></osm>"
      put :create
      assert_response :success, "Couldn't create node."
    end

    # get the bounding box back from the changeset
    get :read, :id => changeset_id
    assert_response :success, "Couldn't read back changeset."
    assert_select "osm>changeset[min_lon=1.0]", 1
    assert_select "osm>changeset[max_lon=1.0]", 1
    assert_select "osm>changeset[min_lat=2.0]", 1
    assert_select "osm>changeset[max_lat=2.0]", 1

    # add another node to it
    with_controller(NodeController.new) do
      content "<osm><node lon='2' lat='1' changeset='#{changeset_id}'/></osm>"
      put :create
      assert_response :success, "Couldn't create second node."
    end

    # get the bounding box back from the changeset
    get :read, :id => changeset_id
    assert_response :success, "Couldn't read back changeset for the second time."
    assert_select "osm>changeset[min_lon=1.0]", 1
    assert_select "osm>changeset[max_lon=2.0]", 1
    assert_select "osm>changeset[min_lat=1.0]", 1
    assert_select "osm>changeset[max_lat=2.0]", 1

    # add (delete) a way to it, which contains a point at (3,3)
    with_controller(WayController.new) do
      content update_changeset(current_ways(:visible_way).to_xml,
                               changeset_id)
      put :delete, :id => current_ways(:visible_way).id
      assert_response :success, "Couldn't delete a way."
    end

    # get the bounding box back from the changeset
    get :read, :id => changeset_id
    assert_response :success, "Couldn't read back changeset for the third time."
    # note that the 3.1 here is because of the bbox overexpansion
    assert_select "osm>changeset[min_lon=1.0]", 1
    assert_select "osm>changeset[max_lon=3.1]", 1
    assert_select "osm>changeset[min_lat=1.0]", 1
    assert_select "osm>changeset[max_lat=3.1]", 1
  end

  ##
  # test that the changeset :include method works as it should
  def test_changeset_include
    basic_authorization users(:public_user).display_name, "test"

    # create a new changeset
    content "<osm><changeset/></osm>"
    put :create
    assert_response :success, "Creating of changeset failed."
    changeset_id = @response.body.to_i

    # NOTE: the include method doesn't over-expand, like inserting
    # a real method does. this is because we expect the client to
    # know what it is doing!
    check_after_include(changeset_id,  1,  1, [ 1,  1,  1,  1])
    check_after_include(changeset_id,  3,  3, [ 1,  1,  3,  3])
    check_after_include(changeset_id,  4,  2, [ 1,  1,  4,  3])
    check_after_include(changeset_id,  2,  2, [ 1,  1,  4,  3])
    check_after_include(changeset_id, -1, -1, [-1, -1,  4,  3])
    check_after_include(changeset_id, -2,  5, [-2, -1,  4,  5])
  end

  ##
  # test that a not found, wrong method with the expand bbox works as expected
  def test_changeset_expand_bbox_error
    basic_authorization users(:public_user).display_name, "test"

    # create a new changeset
    content "<osm><changeset/></osm>"
    put :create
    assert_response :success, "Creating of changeset failed."
    changeset_id = @response.body.to_i

    lon=58.2
    lat=-0.45

    # Try and put
    content "<osm><node lon='#{lon}' lat='#{lat}'/></osm>"
    put :expand_bbox, :id => changeset_id
    assert_response :method_not_allowed, "shouldn't be able to put a bbox expand"

    # Try to get the update
    content "<osm><node lon='#{lon}' lat='#{lat}'/></osm>"
    get :expand_bbox, :id => changeset_id
    assert_response :method_not_allowed, "shouldn't be able to get a bbox expand"

    # Try to use a hopefully missing changeset
    content "<osm><node lon='#{lon}' lat='#{lat}'/></osm>"
    post :expand_bbox, :id => changeset_id+13245
    assert_response :not_found, "shouldn't be able to do a bbox expand on a nonexistant changeset"

  end

  ##
  # test the query functionality of changesets
  def test_query
    get :query, :bbox => "-10,-10, 10, 10"
    assert_response :success, "can't get changesets in bbox"
    assert_changesets [1,4,6]

    get :query, :bbox => "4.5,4.5,4.6,4.6"
    assert_response :success, "can't get changesets in bbox"
    assert_changesets [1]

    # not found when looking for changesets of non-existing users
    get :query, :user => User.maximum(:id) + 1
    assert_response :not_found
    get :query, :display_name => " "
    assert_response :not_found

    # can't get changesets of user 1 without authenticating
    get :query, :user => users(:normal_user).id
    assert_response :not_found, "shouldn't be able to get changesets by non-public user (ID)"
    get :query, :display_name => users(:normal_user).display_name
    assert_response :not_found, "shouldn't be able to get changesets by non-public user (name)"

    # but this should work
    basic_authorization "test@openstreetmap.org", "test"
    get :query, :user => users(:normal_user).id
    assert_response :success, "can't get changesets by user ID"
    assert_changesets [1,3,6,8]

    get :query, :display_name => users(:normal_user).display_name
    assert_response :success, "can't get changesets by user name"
    assert_changesets [1,3,6,8]

    # check that the correct error is given when we provide both UID and name
    get :query, :user => users(:normal_user).id, :display_name => users(:normal_user).display_name
    assert_response :bad_request, "should be a bad request to have both ID and name specified"

    get :query, :user => users(:normal_user).id, :open => true
    assert_response :success, "can't get changesets by user and open"
    assert_changesets [1]

    get :query, :time => '2007-12-31'
    assert_response :success, "can't get changesets by time-since"
    assert_changesets [1,2,4,5,6]

    get :query, :time => '2008-01-01T12:34Z'
    assert_response :success, "can't get changesets by time-since with hour"
    assert_changesets [1,2,4,5,6]

    get :query, :time => '2007-12-31T23:59Z,2008-01-01T00:01Z'
    assert_response :success, "can't get changesets by time-range"
    assert_changesets [1,5,6]

    get :query, :open => 'true'
    assert_response :success, "can't get changesets by open-ness"
    assert_changesets [1,2,4]

    get :query, :closed => 'true'
    assert_response :success, "can't get changesets by closed-ness"
    assert_changesets [3,5,6,7,8]

    get :query, :closed => 'true', :user => users(:normal_user).id
    assert_response :success, "can't get changesets by closed-ness and user"
    assert_changesets [3,6,8]

    get :query, :closed => 'true', :user => users(:public_user).id
    assert_response :success, "can't get changesets by closed-ness and user"
    assert_changesets [7]

    get :query, :changesets => '1,2,3'
    assert_response :success, "can't get changesets by id (as comma-separated string)"
    assert_changesets [1,2,3]

    get :query, :changesets => ''
    assert_response :bad_request, "should be a bad request since changesets is empty"
  end

  ##
  # check that errors are returned if garbage is inserted
  # into query strings
  def test_query_invalid
    [ "abracadabra!",
      "1,2,3,F",
      ";drop table users;"
      ].each do |bbox|
      get :query, :bbox => bbox
      assert_response :bad_request, "'#{bbox}' isn't a bbox"
    end

    [ "now()",
      "00-00-00",
      ";drop table users;",
      ",",
      "-,-"
      ].each do |time|
      get :query, :time => time
      assert_response :bad_request, "'#{time}' isn't a valid time range"
    end

    [ "me",
      "foobar",
      "-1",
      "0"
      ].each do |uid|
      get :query, :user => uid
      assert_response :bad_request, "'#{uid}' isn't a valid user ID"
    end
  end

  ##
  # check updating tags on a changeset
  def test_changeset_update
    ## First try with the non-public user
    changeset = changesets(:normal_user_first_change)
    new_changeset = changeset.to_xml
    new_tag = XML::Node.new "tag"
    new_tag['k'] = "tagtesting"
    new_tag['v'] = "valuetesting"
    new_changeset.find("//osm/changeset").first << new_tag
    content new_changeset

    # try without any authorization
    put :update, :id => changeset.id
    assert_response :unauthorized

    # try with the wrong authorization
    basic_authorization users(:public_user).email, "test"
    put :update, :id => changeset.id
    assert_response :conflict

    # now this should get an unauthorized
    basic_authorization users(:normal_user).email, "test"
    put :update, :id => changeset.id
    assert_require_public_data "user with their data non-public, shouldn't be able to edit their changeset"


    ## Now try with the public user
    changeset = changesets(:public_user_first_change)
    new_changeset = changeset.to_xml
    new_tag = XML::Node.new "tag"
    new_tag['k'] = "tagtesting"
    new_tag['v'] = "valuetesting"
    new_changeset.find("//osm/changeset").first << new_tag
    content new_changeset

    # try without any authorization
    @request.env["HTTP_AUTHORIZATION"] = nil
    put :update, :id => changeset.id
    assert_response :unauthorized

    # try with the wrong authorization
    basic_authorization users(:second_public_user).email, "test"
    put :update, :id => changeset.id
    assert_response :conflict

    # now this should work...
    basic_authorization users(:public_user).email, "test"
    put :update, :id => changeset.id
    assert_response :success

    assert_select "osm>changeset[id=#{changeset.id}]", 1
    assert_select "osm>changeset>tag", 2
    assert_select "osm>changeset>tag[k=tagtesting][v=valuetesting]", 1
  end

  ##
  # check that a user different from the one who opened the changeset
  # can't modify it.
  def test_changeset_update_invalid
    basic_authorization users(:public_user).email, "test"

    changeset = changesets(:normal_user_first_change)
    new_changeset = changeset.to_xml
    new_tag = XML::Node.new "tag"
    new_tag['k'] = "testing"
    new_tag['v'] = "testing"
    new_changeset.find("//osm/changeset").first << new_tag

    content new_changeset
    put :update, :id => changeset.id
    assert_response :conflict
  end

  ##
  # check that a changeset can contain a certain max number of changes.
  ## FIXME should be changed to an integration test due to the with_controller
  def test_changeset_limits
    basic_authorization users(:public_user).email, "test"

    # open a new changeset
    content "<osm><changeset/></osm>"
    put :create
    assert_response :success, "can't create a new changeset"
    cs_id = @response.body.to_i

    # start the counter just short of where the changeset should finish.
    offset = 10
    # alter the database to set the counter on the changeset directly,
    # otherwise it takes about 6 minutes to fill all of them.
    changeset = Changeset.find(cs_id)
    changeset.num_changes = Changeset::MAX_ELEMENTS - offset
    changeset.save!

    with_controller(NodeController.new) do
      # create a new node
      content "<osm><node changeset='#{cs_id}' lat='0.0' lon='0.0'/></osm>"
      put :create
      assert_response :success, "can't create a new node"
      node_id = @response.body.to_i

      get :read, :id => node_id
      assert_response :success, "can't read back new node"
      node_doc = XML::Parser.string(@response.body).parse
      node_xml = node_doc.find("//osm/node").first

      # loop until we fill the changeset with nodes
      offset.times do |i|
        node_xml['lat'] = rand.to_s
        node_xml['lon'] = rand.to_s
        node_xml['version'] = (i+1).to_s

        content node_doc
        put :update, :id => node_id
        assert_response :success, "attempt #{i} should have succeeded"
      end

      # trying again should fail
      node_xml['lat'] = rand.to_s
      node_xml['lon'] = rand.to_s
      node_xml['version'] = offset.to_s

      content node_doc
      put :update, :id => node_id
      assert_response :conflict, "final attempt should have failed"
    end

    changeset = Changeset.find(cs_id)
    assert_equal Changeset::MAX_ELEMENTS + 1, changeset.num_changes

    # check that the changeset is now closed as well
    assert(!changeset.is_open?,
           "changeset should have been auto-closed by exceeding " +
           "element limit.")
  end

  ##
  # This should display the last 20 changesets closed.
  def test_list
    get :list, {:format => "html"}
    assert_response :success
    assert_template "history"
    assert_template :layout => "map"
    assert_select "h2", :text => "Changesets", :count => 1

    get :list, {:format => "html", :list => '1', :bbox => '-180,-90,90,180'}
    assert_response :success
    assert_template "list"

    changesets = Changeset.
        where("num_changes > 0 and min_lon is not null").
        order(:created_at => :desc).
        limit(20)
    assert changesets.size <= 20

    # Now check that all 20 (or however many were returned) changesets are in the html
    assert_select "li", :count => changesets.size
    changesets.each do |changeset|
      # FIXME this test needs rewriting - test for table contents
    end
  end

  ##
  # This should display the last 20 changesets closed.
  def test_list_xhr
    xhr :get, :list, {:format => "html"}
    assert_response :success
    assert_template "history"
    assert_template :layout => "xhr"
    assert_select "h2", :text => "Changesets", :count => 1

    get :list, {:format => "html", :list => '1', :bbox => '-180,-90,90,180'}
    assert_response :success
    assert_template "list"

    changesets = Changeset.
        where("num_changes > 0 and min_lon is not null").
        order(:created_at => :desc).
        limit(20)
    assert changesets.size <= 20

    # Now check that all 20 (or however many were returned) changesets are in the html
    assert_select "li", :count => changesets.size
    changesets.each do |changeset|
      # FIXME this test needs rewriting - test for table contents
    end
  end

  ##
  # Checks the display of the user changesets listing
  def test_list_user
    user = users(:public_user)
    get :list, {:format => "html", :display_name => user.display_name}
    assert_response :success
    assert_template "history"
    ## FIXME need to add more checks to see which if edits are actually shown if your data is public
  end

  ##
  # Check the not found of the list user changesets
  def test_list_user_not_found
    get :list, {:format => "html", :display_name => "Some random user"}
    assert_response :not_found
    assert_template 'user/no_such_user'
  end

  ##
  # This should display the last 20 changesets closed.
  def test_feed
    changesets = Changeset.where("num_changes > 0").order(:created_at => :desc).limit(20)
    assert changesets.size <= 20
    get :feed, {:format => "atom"}
    assert_response :success
    assert_template "list"
    # Now check that all 20 (or however many were returned) changesets are in the html
    assert_select "feed", :count => 1
    assert_select "entry", :count => changesets.size
    changesets.each do |changeset|
      # FIXME this test needs rewriting - test for feed contents
    end
  end

  ##
  # Checks the display of the user changesets feed
  def test_feed_user
    user = users(:public_user)
    get :feed, {:format => "atom", :display_name => user.display_name}
    assert_response :success
    assert_template "list"
    assert_equal "application/atom+xml", response.content_type
    ## FIXME need to add more checks to see which if edits are actually shown if your data is public
  end

  ##
  # Check the not found of the user changesets feed
  def test_feed_user_not_found
    get :feed, {:format => "atom", :display_name => "Some random user"}
    assert_response :not_found
  end

  ##
  # check that the changeset download for a changeset with a redacted
  # element in it doesn't contain that element.
  def test_diff_download_redacted
    changeset_id = changesets(:public_user_first_change).id

    get :download, :id => changeset_id
    assert_response :success

    assert_select "osmChange", 1
    # this changeset contains node 17 in versions 1 & 2, but 1 should
    # be hidden.
    assert_select "osmChange node[id=17]", 1
    assert_select "osmChange node[id=17][version=1]", 0
  end

  ##
  # create comment success
  def test_create_comment_success
    basic_authorization(users(:public_user).email, 'test')

    assert_difference('ChangesetComment.count') do
      post :comment, { :id => changesets(:normal_user_closed_change).id, :text => 'This is a comment' }
    end
    assert_response :success
  end

  ##
  # create comment fail
  def test_create_comment_fail
    # unauthorized
    post :comment, { :id => changesets(:normal_user_closed_change).id, :text => 'This is a comment' }
    assert_response :unauthorized

    basic_authorization(users(:public_user).email, 'test')

    # bad changeset id
    assert_no_difference('ChangesetComment.count') do
      post :comment, { :id => 999111, :text => 'This is a comment' }
    end
    assert_response :not_found

    # not closed changeset
    assert_no_difference('ChangesetComment.count') do
      post :comment, { :id => changesets(:normal_user_first_change).id, :text => 'This is a comment' }
    end
    assert_response :conflict

    # no text
    assert_no_difference('ChangesetComment.count') do
      post :comment, { :id => changesets(:normal_user_closed_change).id }
    end
    assert_response :bad_request

    # empty text
    assert_no_difference('ChangesetComment.count') do
      post :comment, { :id => changesets(:normal_user_closed_change).id, :text => '' }
    end
    assert_response :bad_request    
  end

  ##
  # test subscribe success
  def test_subscribe_success
    basic_authorization(users(:public_user).email, 'test')
    changeset = changesets(:normal_user_closed_change)

    assert_difference('changeset.subscribers.count') do
      post :subscribe, { :id => changeset.id }
    end
    assert_response :success
  end

  ##
  # test subscribe fail
  def test_subscribe_fail
    # unauthorized
    changeset = changesets(:normal_user_closed_change)
    assert_no_difference('changeset.subscribers.count') do
      post :subscribe, { :id => changeset.id }
    end
    assert_response :unauthorized

    basic_authorization(users(:public_user).email, 'test')

    # bad changeset id
    assert_no_difference('changeset.subscribers.count') do
      post :subscribe, { :id => 999111 }
    end
    assert_response :not_found

    # not closed changeset
    changeset = changesets(:normal_user_first_change)
    assert_no_difference('changeset.subscribers.count') do
      post :subscribe, { :id => changeset.id }
    end
    assert_response :conflict

    # trying to subscribe when already subscribed
    changeset = changesets(:normal_user_subscribed_change)
    assert_no_difference('changeset.subscribers.count') do
      post :subscribe, { :id => changeset.id }
    end
    assert_response :conflict
  end

  ##
  # test unsubscribe success
  def test_unsubscribe_success
    basic_authorization(users(:public_user).email, 'test')
    changeset = changesets(:normal_user_subscribed_change)

    assert_difference('changeset.subscribers.count', -1) do
      post :unsubscribe, { :id => changeset.id }
    end
    assert_response :success
  end

  ##
  # test unsubscribe fail
  def test_unsubscribe_fail
    # unauthorized
    changeset = changesets(:normal_user_closed_change)
    assert_no_difference('changeset.subscribers.count') do
      post :unsubscribe, { :id => changeset.id }
    end
    assert_response :unauthorized

    basic_authorization(users(:public_user).email, 'test')

    # bad changeset id
    assert_no_difference('changeset.subscribers.count', -1) do
      post :unsubscribe, { :id => 999111 }
    end
    assert_response :not_found

    # not closed changeset
    changeset = changesets(:normal_user_first_change)
    assert_no_difference('changeset.subscribers.count', -1) do
      post :unsubscribe, { :id => changeset.id }
    end
    assert_response :conflict

    # trying to unsubscribe when not subscribed
    changeset = changesets(:normal_user_closed_change)
    assert_no_difference('changeset.subscribers.count') do
      post :unsubscribe, { :id => changeset.id }
    end
    assert_response :not_found
  end

  ##
  # test hide comment fail
  def test_hide_comment_fail
    # unauthorized
    comment = changeset_comments(:normal_comment_1)
    assert('comment.visible') do
      post :hide_comment, { :id => comment.id }
      assert_response :unauthorized
    end

    basic_authorization(users(:public_user).email, 'test')

    # not a moderator
    assert('comment.visible') do
      post :hide_comment, { :id => comment.id }
      assert_response :forbidden
    end

    basic_authorization(users(:moderator_user).email, 'test')

    # bad comment id
    post :hide_comment, { :id => 999111 }
    assert_response :not_found
  end

  ##
  # test hide comment succes
  def test_hide_comment_success
    comment = changeset_comments(:normal_comment_1)

    basic_authorization(users(:moderator_user).email, 'test')

    assert('!comment.visible') do
      post :hide_comment, { :id => comment.id }
    end
    assert_response :success
  end

  ##
  # test unhide comment fail
  def test_unhide_comment_fail
    # unauthorized
    comment = changeset_comments(:normal_comment_1)
    assert('comment.visible') do
      post :unhide_comment, { :id => comment.id }
      assert_response :unauthorized
    end
    
    basic_authorization(users(:public_user).email, 'test')

    # not a moderator
    assert('comment.visible') do
      post :unhide_comment, { :id => comment.id }
      assert_response :forbidden
    end

    basic_authorization(users(:moderator_user).email, 'test')

    # bad comment id
    post :unhide_comment, { :id => 999111 }
    assert_response :not_found
  end

  ##
  # test unhide comment succes
  def test_unhide_comment_success
    comment = changeset_comments(:normal_comment_1)

    basic_authorization(users(:moderator_user).email, 'test')

    assert('!comment.visible') do
      post :unhide_comment, { :id => comment.id }
    end
    assert_response :success
  end

  ##
  # test comments feed
  def test_comments_feed
    get :comments_feed, {:format => "rss"}
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 3
      end
    end

    get :comments_feed, { :id => changesets(:normal_user_closed_change), :format => "rss"}
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 3
      end
    end
  end

  #------------------------------------------------------------
  # utility functions
  #------------------------------------------------------------

  ##
  # boilerplate for checking that certain changesets exist in the
  # output.
  def assert_changesets(ids)
    assert_select "osm>changeset", ids.size
    ids.each do |id|
      assert_select "osm>changeset[id=#{id}]", 1
    end
  end

  ##
  # call the include method and assert properties of the bbox
  def check_after_include(changeset_id, lon, lat, bbox)
    content "<osm><node lon='#{lon}' lat='#{lat}'/></osm>"
    post :expand_bbox, :id => changeset_id
    assert_response :success, "Setting include of changeset failed: #{@response.body}"

    # check exactly one changeset
    assert_select "osm>changeset", 1
    assert_select "osm>changeset[id=#{changeset_id}]", 1

    # check the bbox
    doc = XML::Parser.string(@response.body).parse
    changeset = doc.find("//osm/changeset").first
    assert_equal bbox[0], changeset['min_lon'].to_f, "min lon"
    assert_equal bbox[1], changeset['min_lat'].to_f, "min lat"
    assert_equal bbox[2], changeset['max_lon'].to_f, "max lon"
    assert_equal bbox[3], changeset['max_lat'].to_f, "max lat"
  end

  ##
  # update the changeset_id of a way element
  def update_changeset(xml, changeset_id)
    xml_attr_rewrite(xml, 'changeset', changeset_id)
  end

  ##
  # update an attribute in a way element
  def xml_attr_rewrite(xml, name, value)
    xml.find("//osm/way").first[name] = value.to_s
    return xml
  end
end
