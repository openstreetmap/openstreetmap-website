require File.dirname(__FILE__) + '/../test_helper'
require 'changeset_controller'

class ChangesetControllerTest < ActionController::TestCase
  api_fixtures

  def basic_authorization(user, pass)
    @request.env["HTTP_AUTHORIZATION"] = "Basic %s" % Base64.encode64("#{user}:#{pass}")
  end

  def content(c)
    @request.env["RAW_POST_DATA"] = c.to_s
  end
  
  # -----------------------
  # Test simple changeset creation
  # -----------------------
  
  def test_create
    basic_authorization "test@openstreetmap.org", "test"
    
    # Create the first user's changeset
    content "<osm><changeset>" +
      "<tag k='created_by' v='osm test suite checking changesets'/>" + 
      "</changeset></osm>"
    put :create
    
    assert_response :success, "Creation of changeset did not return sucess status"
    newid = @response.body
  end
  
  def test_create_invalid
    basic_authorization "test@openstreetmap.org", "test"
    content "<osm><changeset></osm>"
    put :create
    assert_response :bad_request, "creating a invalid changeset should fail"
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
  end
  
  def test_close
    # FIXME FIXME FIXME!
  end

  ##
  # upload something simple, but valid and check that it can 
  # be read back ok.
  def test_upload_simple_valid
    basic_authorization "test@openstreetmap.org", "test"

    # simple diff to change a node, way and relation by removing 
    # their tags
    diff = <<EOF
<osmChange>
 <modify>
  <node id='1' lon='0' lat='0' changeset='1' version='1'/>
  <way id='1' changeset='1' version='1'>
   <nd ref='3'/>
  </way>
 </modify>
 <modify>
  <relation id='1' changeset='1' version='1'>
   <member type='way' role='some' ref='3'/>
   <member type='node' role='some' ref='5'/>
   <member type='relation' role='some' ref='3'/>
  </relation>
 </modify>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => 1
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
    basic_authorization "test@openstreetmap.org", "test"

    # simple diff to create a node way and relation using placeholders
    diff = <<EOF
<osmChange>
 <create>
  <node id='-1' lon='0' lat='0' changeset='1'>
   <tag k='foo' v='bar'/>
   <tag k='baz' v='bat'/>
  </node>
  <way id='-1' changeset='1'>
   <nd ref='3'/>
  </way>
 </create>
 <create>
  <relation id='-1' changeset='1'>
   <member type='way' role='some' ref='3'/>
   <member type='node' role='some' ref='5'/>
   <member type='relation' role='some' ref='3'/>
  </relation>
 </create>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => 1
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
    basic_authorization "test@openstreetmap.org", "test"

    diff = XML::Document.new
    diff.root = XML::Node.new "osmChange"
    delete = XML::Node.new "delete"
    diff.root << delete
    delete << current_relations(:visible_relation).to_xml_node
    delete << current_relations(:used_relation).to_xml_node
    delete << current_ways(:used_way).to_xml_node
    delete << current_nodes(:node_used_by_relationship).to_xml_node

    # upload it
    content diff
    post :upload, :id => 1
    assert_response :success, 
      "can't upload a deletion diff to changeset: #{@response.body}"

    # check that everything was deleted
    assert_equal false, Node.find(current_nodes(:node_used_by_relationship).id).visible
    assert_equal false, Way.find(current_ways(:used_way).id).visible
    assert_equal false, Relation.find(current_relations(:visible_relation).id).visible
    assert_equal false, Relation.find(current_relations(:used_relation).id).visible
  end

  ##
  # test that deleting stuff in a transaction doesn't bypass the checks
  # to ensure that used elements are not deleted.
  def test_upload_delete_invalid
    basic_authorization "test@openstreetmap.org", "test"

    diff = XML::Document.new
    diff.root = XML::Node.new "osmChange"
    delete = XML::Node.new "delete"
    diff.root << delete
    delete << current_relations(:visible_relation).to_xml_node
    delete << current_ways(:used_way).to_xml_node
    delete << current_nodes(:node_used_by_relationship).to_xml_node

    # upload it
    content diff
    post :upload, :id => 1
    assert_response :precondition_failed, 
      "shouldn't be able to upload a invalid deletion diff: #{@response.body}"

    # check that nothing was, in fact, deleted
    assert_equal true, Node.find(current_nodes(:node_used_by_relationship).id).visible
    assert_equal true, Way.find(current_ways(:used_way).id).visible
    assert_equal true, Relation.find(current_relations(:visible_relation).id).visible
  end

  ##
  # upload something which creates new objects and inserts them into
  # existing containers using placeholders.
  def test_upload_complex
    basic_authorization "test@openstreetmap.org", "test"

    # simple diff to create a node way and relation using placeholders
    diff = <<EOF
<osmChange>
 <create>
  <node id='-1' lon='0' lat='0' changeset='1'>
   <tag k='foo' v='bar'/>
   <tag k='baz' v='bat'/>
  </node>
 </create>
 <modify>
  <way id='1' changeset='1' version='1'>
   <nd ref='-1'/>
   <nd ref='3'/>
  </way>
  <relation id='1' changeset='1' version='1'>
   <member type='way' role='some' ref='3'/>
   <member type='node' role='some' ref='-1'/>
   <member type='relation' role='some' ref='3'/>
  </relation>
 </modify>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => 1
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
    basic_authorization "test@openstreetmap.org", "test"

    # simple diff to create a node way and relation using placeholders
    diff = <<EOF
<osmChange>
 <modify>
  <node id='1' lon='0' lat='0' changeset='1' version='1'/>
  <way id='1' changeset='1' version='1'>
   <nd ref='3'/>
  </way>
 </modify>
 <modify>
  <relation id='1' changeset='1' version='1'>
   <member type='way' role='some' ref='3'/>
   <member type='node' role='some' ref='5'/>
   <member type='relation' role='some' ref='3'/>
  </relation>
 </modify>
 <create>
  <node id='-1' changeset='4'>
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
    post :upload, :id => 1
    assert_response :conflict, 
      "uploading a diff with multiple changsets should have failed"

    # check that objects are unmodified
    assert_nodes_are_equal(node, Node.find(1))
    assert_ways_are_equal(way, Way.find(1))
  end
    
  ##
  # upload multiple versions of the same element in the same diff.
  def test_upload_multiple_valid
    basic_authorization "test@openstreetmap.org", "test"

    # change the location of a node multiple times, each time referencing
    # the last version. doesn't this depend on version numbers being
    # sequential?
    diff = <<EOF
<osmChange>
 <modify>
  <node id='1' lon='0' lat='0' changeset='1' version='1'/>
  <node id='1' lon='1' lat='0' changeset='1' version='2'/>
  <node id='1' lon='1' lat='1' changeset='1' version='3'/>
  <node id='1' lon='1' lat='2' changeset='1' version='4'/>
  <node id='1' lon='2' lat='2' changeset='1' version='5'/>
  <node id='1' lon='3' lat='2' changeset='1' version='6'/>
  <node id='1' lon='3' lat='3' changeset='1' version='7'/>
  <node id='1' lon='9' lat='9' changeset='1' version='8'/>
 </modify>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => 1
    assert_response :success, 
      "can't upload multiple versions of an element in a diff: #{@response.body}"
  end

  ##
  # upload multiple versions of the same element in the same diff, but
  # keep the version numbers the same.
  def test_upload_multiple_duplicate
    basic_authorization "test@openstreetmap.org", "test"

    diff = <<EOF
<osmChange>
 <modify>
  <node id='1' lon='0' lat='0' changeset='1' version='1'/>
  <node id='1' lon='1' lat='1' changeset='1' version='1'/>
 </modify>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => 1
    assert_response :conflict, 
      "shouldn't be able to upload the same element twice in a diff: #{@response.body}"
  end

  ##
  # try to upload some elements without specifying the version
  def test_upload_missing_version
    basic_authorization "test@openstreetmap.org", "test"

    diff = <<EOF
<osmChange>
 <modify>
  <node id='1' lon='1' lat='1' changeset='1'/>
 </modify>
</osmChange>
EOF

    # upload it
    content diff
    post :upload, :id => 1
    assert_response :bad_request, 
      "shouldn't be able to upload an element without version: #{@response.body}"
  end
  
  ##
  # try to upload with commands other than create, modify, or delete
  def test_action_upload_invalid
    basic_authorization "test@openstreetmap.org", "test"
    
    diff = <<EOF
<osmChange>
  <ping>
    <node id='1' lon='1' lat='1' changeset='1' />
  </ping>
</osmChange>
EOF
  content diff
  post :upload, :id => 1
  assert_response :bad_request, "Shouldn't be able to upload a diff with the action ping"
  assert_equal @response.body, "Unknown action ping, choices are create, modify, delete."
  end

  ##
  # when we make some simple changes we get the same changes back from the 
  # diff download.
  def test_diff_download_simple
    basic_authorization(users(:normal_user).email, "test")

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
  # when we make some complex changes we get the same changes back from the 
  # diff download.
  def test_diff_download_complex
    basic_authorization(users(:normal_user).email, "test")

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

  ##
  # check that the bounding box of a changeset gets updated correctly
  def test_changeset_bbox
    basic_authorization "test@openstreetmap.org", "test"

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

    # add (delete) a way to it
    with_controller(WayController.new) do
      content update_changeset(current_ways(:visible_way).to_xml,
                               changeset_id)
      put :delete, :id => current_ways(:visible_way).id
      assert_response :success, "Couldn't delete a way."
    end

    # get the bounding box back from the changeset
    get :read, :id => changeset_id
    assert_response :success, "Couldn't read back changeset for the third time."
    assert_select "osm>changeset[min_lon=1.0]", 1
    assert_select "osm>changeset[max_lon=3.1]", 1
    assert_select "osm>changeset[min_lat=1.0]", 1
    assert_select "osm>changeset[max_lat=3.1]", 1    
  end

  ##
  # test that the changeset :include method works as it should
  def test_changeset_include
    basic_authorization "test@openstreetmap.org", "test"

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
  # check searching for changesets by bbox
  def test_changeset_by_bbox
    get :query, :bbox => "-10,-10, 10, 10"
    assert_response :success, "can't get changesets in bbox"
    # FIXME: write the actual test bit after fixing the fixtures!
  end

  ##
  # check updating tags on a changeset
  def test_changeset_update
    basic_authorization "test@openstreetmap.org", "test"

    changeset = changesets(:normal_user_first_change)
    new_changeset = changeset.to_xml
    new_tag = XML::Node.new "tag"
    new_tag['k'] = "testing"
    new_tag['v'] = "testing"
    new_changeset.find("//osm/changeset").first << new_tag

    content new_changeset
    put :update, :id => changeset.id
    assert_response :success

    assert_select "osm>changeset[id=#{changeset.id}]", 1
    assert_select "osm>changeset>tag", 2
    assert_select "osm>changeset>tag[k=testing][v=testing]", 1
  end
  
  ##
  # check that a user different from the one who opened the changeset
  # can't modify it.
  def test_changeset_update_invalid
    basic_authorization "test@example.com", "test"

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

  #------------------------------------------------------------
  # utility functions
  #------------------------------------------------------------

  ##
  # call the include method and assert properties of the bbox
  def check_after_include(changeset_id, lon, lat, bbox)
    content "<osm><node lon='#{lon}' lat='#{lat}'/></osm>"
    post :include, :id => changeset_id
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
