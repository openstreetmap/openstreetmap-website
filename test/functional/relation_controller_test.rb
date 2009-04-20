require File.dirname(__FILE__) + '/../test_helper'
require 'relation_controller'

class RelationControllerTest < ActionController::TestCase
  api_fixtures

  # -------------------------------------
  # Test reading relations.
  # -------------------------------------

  def test_read
    # check that a visible relation is returned properly
    get :read, :id => current_relations(:visible_relation).id
    assert_response :success

    # check that an invisible relation is not returned
    get :read, :id => current_relations(:invisible_relation).id
    assert_response :gone

    # check chat a non-existent relation is not returned
    get :read, :id => 0
    assert_response :not_found
  end

  ##
  # check that all relations containing a particular node, and no extra
  # relations, are returned from the relations_for_node call.
  def test_relations_for_node
    check_relations_for_element(:relations_for_node, "node", 
                                current_nodes(:node_used_by_relationship).id,
                                [ :visible_relation, :used_relation ])
  end

  def test_relations_for_way
    check_relations_for_element(:relations_for_way, "way",
                                current_ways(:used_way).id,
                                [ :visible_relation ])
  end

  def test_relations_for_relation
    check_relations_for_element(:relations_for_relation, "relation",
                                current_relations(:used_relation).id,
                                [ :visible_relation ])
  end

  def check_relations_for_element(method, type, id, expected_relations)
    # check the "relations for relation" mode
    get method, :id => id
    assert_response :success

    # count one osm element
    assert_select "osm[version=#{API_VERSION}][generator=\"OpenStreetMap server\"]", 1

    # we should have only the expected number of relations
    assert_select "osm>relation", expected_relations.size

    # and each of them should contain the node we originally searched for
    expected_relations.each do |r|
      relation_id = current_relations(r).id
      assert_select "osm>relation#?", relation_id
      assert_select "osm>relation#?>member[type=\"#{type}\"][ref=#{id}]", relation_id
    end
  end

  def test_full
    # check the "full" mode
    get :full, :id => current_relations(:visible_relation).id
    assert_response :success
    # FIXME check whether this contains the stuff we want!
    if $VERBOSE
        print @response.body
    end
  end

  # -------------------------------------
  # Test simple relation creation.
  # -------------------------------------

  def test_create
    basic_authorization "test@openstreetmap.org", "test"
    
    # put the relation in a dummy fixture changset
    changeset_id = changesets(:normal_user_first_change).id

    # create an relation without members
    content "<osm><relation changeset='#{changeset_id}'><tag k='test' v='yes' /></relation></osm>"
    put :create
    # hope for success
    assert_response :success, 
        "relation upload did not return success status"
    # read id of created relation and search for it
    relationid = @response.body
    checkrelation = Relation.find(relationid)
    assert_not_nil checkrelation, 
        "uploaded relation not found in data base after upload"
    # compare values
    assert_equal checkrelation.members.length, 0, 
        "saved relation contains members but should not"
    assert_equal checkrelation.tags.length, 1, 
        "saved relation does not contain exactly one tag"
    assert_equal changeset_id, checkrelation.changeset.id,
        "saved relation does not belong in the changeset it was assigned to"
    assert_equal users(:normal_user).id, checkrelation.changeset.user_id, 
        "saved relation does not belong to user that created it"
    assert_equal true, checkrelation.visible, 
        "saved relation is not visible"
    # ok the relation is there but can we also retrieve it?
    get :read, :id => relationid
    assert_response :success


    ###
    # create an relation with a node as member
    # This time try with a role attribute in the relation
    nid = current_nodes(:used_node_1).id
    content "<osm><relation changeset='#{changeset_id}'>" +
      "<member  ref='#{nid}' type='node' role='some'/>" +
      "<tag k='test' v='yes' /></relation></osm>"
    put :create
    # hope for success
    assert_response :success, 
        "relation upload did not return success status"
    # read id of created relation and search for it
    relationid = @response.body
    checkrelation = Relation.find(relationid)
    assert_not_nil checkrelation, 
        "uploaded relation not found in data base after upload"
    # compare values
    assert_equal checkrelation.members.length, 1, 
        "saved relation does not contain exactly one member"
    assert_equal checkrelation.tags.length, 1, 
        "saved relation does not contain exactly one tag"
    assert_equal changeset_id, checkrelation.changeset.id,
        "saved relation does not belong in the changeset it was assigned to"
    assert_equal users(:normal_user).id, checkrelation.changeset.user_id, 
        "saved relation does not belong to user that created it"
    assert_equal true, checkrelation.visible, 
        "saved relation is not visible"
    # ok the relation is there but can we also retrieve it?
    
    get :read, :id => relationid
    assert_response :success
    
    
    ###
    # create an relation with a node as member, this time test that we don't 
    # need a role attribute to be included
    nid = current_nodes(:used_node_1).id
    content "<osm><relation changeset='#{changeset_id}'>" +
      "<member  ref='#{nid}' type='node'/>"+
      "<tag k='test' v='yes' /></relation></osm>"
    put :create
    # hope for success
    assert_response :success, 
        "relation upload did not return success status"
    # read id of created relation and search for it
    relationid = @response.body
    checkrelation = Relation.find(relationid)
    assert_not_nil checkrelation, 
        "uploaded relation not found in data base after upload"
    # compare values
    assert_equal checkrelation.members.length, 1, 
        "saved relation does not contain exactly one member"
    assert_equal checkrelation.tags.length, 1, 
        "saved relation does not contain exactly one tag"
    assert_equal changeset_id, checkrelation.changeset.id,
        "saved relation does not belong in the changeset it was assigned to"
    assert_equal users(:normal_user).id, checkrelation.changeset.user_id, 
        "saved relation does not belong to user that created it"
    assert_equal true, checkrelation.visible, 
        "saved relation is not visible"
    # ok the relation is there but can we also retrieve it?
    
    get :read, :id => relationid
    assert_response :success

    ###
    # create an relation with a way and a node as members
    nid = current_nodes(:used_node_1).id
    wid = current_ways(:used_way).id
    content "<osm><relation changeset='#{changeset_id}'>" +
      "<member type='node' ref='#{nid}' role='some'/>" +
      "<member type='way' ref='#{wid}' role='other'/>" +
      "<tag k='test' v='yes' /></relation></osm>"
    put :create
    # hope for success
    assert_response :success, 
        "relation upload did not return success status"
    # read id of created relation and search for it
    relationid = @response.body
    checkrelation = Relation.find(relationid)
    assert_not_nil checkrelation, 
        "uploaded relation not found in data base after upload"
    # compare values
    assert_equal checkrelation.members.length, 2, 
        "saved relation does not have exactly two members"
    assert_equal checkrelation.tags.length, 1, 
        "saved relation does not contain exactly one tag"
    assert_equal changeset_id, checkrelation.changeset.id,
        "saved relation does not belong in the changeset it was assigned to"
    assert_equal users(:normal_user).id, checkrelation.changeset.user_id, 
        "saved relation does not belong to user that created it"
    assert_equal true, checkrelation.visible, 
        "saved relation is not visible"
    # ok the relation is there but can we also retrieve it?
    get :read, :id => relationid
    assert_response :success

  end

  # -------------------------------------
  # Test creating some invalid relations.
  # -------------------------------------

  def test_create_invalid
    basic_authorization "test@openstreetmap.org", "test"

    # put the relation in a dummy fixture changset
    changeset_id = changesets(:normal_user_first_change).id

    # create a relation with non-existing node as member
    content "<osm><relation changeset='#{changeset_id}'>" +
      "<member type='node' ref='0'/><tag k='test' v='yes' />" +
      "</relation></osm>"
    put :create
    # expect failure
    assert_response :precondition_failed, 
        "relation upload with invalid node did not return 'precondition failed'"
  end

  # -------------------------------------
  # Test creating a relation, with some invalid XML
  # -------------------------------------
  def test_create_invalid_xml
    basic_authorization "test@openstreetmap.org", "test"
    
    # put the relation in a dummy fixture changeset that works
    changeset_id = changesets(:normal_user_first_change).id
    
    # create some xml that should return an error
    content "<osm><relation changeset='#{changeset_id}'>" +
    "<member type='type' ref='#{current_nodes(:used_node_1).id}' role=''/>" +
    "<tag k='tester' v='yep'/></relation></osm>"
    put :create
    # expect failure
    assert_response :bad_request
    assert_match(/Cannot parse valid relation from xml string/, @response.body)
    assert_match(/The type is not allowed only, /, @response.body)
  end
  
  
  # -------------------------------------
  # Test deleting relations.
  # -------------------------------------
  
  def test_delete
    # first try to delete relation without auth
    delete :delete, :id => current_relations(:visible_relation).id
    assert_response :unauthorized

    # now set auth
    basic_authorization("test@openstreetmap.org", "test");  

    # this shouldn't work, as we should need the payload...
    delete :delete, :id => current_relations(:visible_relation).id
    assert_response :bad_request

    # try to delete without specifying a changeset
    content "<osm><relation id='#{current_relations(:visible_relation).id}'/></osm>"
    delete :delete, :id => current_relations(:visible_relation).id
    assert_response :bad_request
    assert_match(/You are missing the required changeset in the relation/, @response.body)

    # try to delete with an invalid (closed) changeset
    content update_changeset(current_relations(:visible_relation).to_xml,
                             changesets(:normal_user_closed_change).id)
    delete :delete, :id => current_relations(:visible_relation).id
    assert_response :conflict

    # try to delete with an invalid (non-existent) changeset
    content update_changeset(current_relations(:visible_relation).to_xml,0)
    delete :delete, :id => current_relations(:visible_relation).id
    assert_response :conflict

    # this won't work because the relation is in-use by another relation
    content(relations(:used_relation).to_xml)
    delete :delete, :id => current_relations(:used_relation).id
    assert_response :precondition_failed, 
       "shouldn't be able to delete a relation used in a relation (#{@response.body})"

    # this should work when we provide the appropriate payload...
    content(relations(:visible_relation).to_xml)
    delete :delete, :id => current_relations(:visible_relation).id
    assert_response :success

    # valid delete should return the new version number, which should
    # be greater than the old version number
    assert @response.body.to_i > current_relations(:visible_relation).version,
       "delete request should return a new version number for relation"

    # this won't work since the relation is already deleted
    content(relations(:invisible_relation).to_xml)
    delete :delete, :id => current_relations(:invisible_relation).id
    assert_response :gone

    # this works now because the relation which was using this one 
    # has been deleted.
    content(relations(:used_relation).to_xml)
    delete :delete, :id => current_relations(:used_relation).id
    assert_response :success, 
       "should be able to delete a relation used in an old relation (#{@response.body})"

    # this won't work since the relation never existed
    delete :delete, :id => 0
    assert_response :not_found
  end

  ##
  # when a relation's tag is modified then it should put the bounding
  # box of all its members into the changeset.
  def test_tag_modify_bounding_box
    # in current fixtures, relation 5 contains nodes 3 and 5 (node 3
    # indirectly via way 3), so the bbox should be [3,3,5,5].
    check_changeset_modify([3,3,5,5]) do |changeset_id|
      # add a tag to an existing relation
      relation_xml = current_relations(:visible_relation).to_xml
      relation_element = relation_xml.find("//osm/relation").first
      new_tag = XML::Node.new("tag")
      new_tag['k'] = "some_new_tag"
      new_tag['v'] = "some_new_value"
      relation_element << new_tag
      
      # update changeset ID to point to new changeset
      update_changeset(relation_xml, changeset_id)
      
      # upload the change
      content relation_xml
      put :update, :id => current_relations(:visible_relation).id
      assert_response :success, "can't update relation for tag/bbox test"
    end
  end

  ##
  # add a member to a relation and check the bounding box is only that
  # element.
  def test_add_member_bounding_box
    check_changeset_modify([4,4,4,4]) do |changeset_id|
      # add node 4 (4,4) to an existing relation
      relation_xml = current_relations(:visible_relation).to_xml
      relation_element = relation_xml.find("//osm/relation").first
      new_member = XML::Node.new("member")
      new_member['ref'] = current_nodes(:used_node_2).id.to_s
      new_member['type'] = "node"
      new_member['role'] = "some_role"
      relation_element << new_member
      
      # update changeset ID to point to new changeset
      update_changeset(relation_xml, changeset_id)
      
      # upload the change
      content relation_xml
      put :update, :id => current_relations(:visible_relation).id
      assert_response :success, "can't update relation for add node/bbox test"
    end
  end
  
  ##
  # remove a member from a relation and check the bounding box is 
  # only that element.
  def test_remove_member_bounding_box
    check_changeset_modify([5,5,5,5]) do |changeset_id|
      # remove node 5 (5,5) from an existing relation
      relation_xml = current_relations(:visible_relation).to_xml
      relation_xml.
        find("//osm/relation/member[@type='node'][@ref='5']").
        first.remove!
      
      # update changeset ID to point to new changeset
      update_changeset(relation_xml, changeset_id)
      
      # upload the change
      content relation_xml
      put :update, :id => current_relations(:visible_relation).id
      assert_response :success, "can't update relation for remove node/bbox test"
    end
  end
  
  ##
  # check that relations are ordered
  def test_relation_member_ordering
    basic_authorization("test@openstreetmap.org", "test");  

    doc_str = <<OSM
<osm>
 <relation changeset='1'>
  <member ref='1' type='node' role='first'/>
  <member ref='3' type='node' role='second'/>
  <member ref='1' type='way' role='third'/>
  <member ref='3' type='way' role='fourth'/>
 </relation>
</osm>
OSM
    doc = XML::Parser.string(doc_str).parse

    content doc
    put :create
    assert_response :success, "can't create a relation: #{@response.body}"
    relation_id = @response.body.to_i

    # get it back and check the ordering
    get :read, :id => relation_id
    assert_response :success, "can't read back the relation: #{@response.body}"
    check_ordering(doc, @response.body)

    # insert a member at the front
    new_member = XML::Node.new "member"
    new_member['ref'] = 5.to_s
    new_member['type'] = 'node'
    new_member['role'] = 'new first'
    doc.find("//osm/relation").first.child.prev = new_member
    # update the version, should be 1?
    doc.find("//osm/relation").first['id'] = relation_id.to_s
    doc.find("//osm/relation").first['version'] = 1.to_s

    # upload the next version of the relation
    content doc
    put :update, :id => relation_id
    assert_response :success, "can't update relation: #{@response.body}"
    new_version = @response.body.to_i

    # get it back again and check the ordering again
    get :read, :id => relation_id
    assert_response :success, "can't read back the relation: #{@response.body}"
    check_ordering(doc, @response.body)
  end

  ## 
  # check that relations can contain duplicate members
  def test_relation_member_duplicates
    basic_authorization("test@openstreetmap.org", "test");  

    doc_str = <<OSM
<osm>
 <relation changeset='1'>
  <member ref='1' type='node' role='forward'/>
  <member ref='3' type='node' role='forward'/>
  <member ref='1' type='node' role='forward'/>
  <member ref='3' type='node' role='forward'/>
 </relation>
</osm>
OSM
    doc = XML::Parser.string(doc_str).parse

    content doc
    put :create
    assert_response :success, "can't create a relation: #{@response.body}"
    relation_id = @response.body.to_i

    # get it back and check the ordering
    get :read, :id => relation_id
    assert_response :success, "can't read back the relation: #{@response.body}"
    check_ordering(doc, @response.body)
  end

  # ============================================================
  # utility functions
  # ============================================================

  ##
  # checks that the XML document and the string arguments have
  # members in the same order.
  def check_ordering(doc, xml)
    new_doc = XML::Parser.string(xml).parse

    doc_members = doc.find("//osm/relation/member").collect do |m|
      [m['ref'].to_i, m['type'].to_sym, m['role']]
    end

    new_members = new_doc.find("//osm/relation/member").collect do |m|
      [m['ref'].to_i, m['type'].to_sym, m['role']]
    end

    doc_members.zip(new_members).each do |d, n|
      assert_equal d, n, "members are not equal - ordering is wrong? (#{doc}, #{xml})"
    end
  end

  ##
  # create a changeset and yield to the caller to set it up, then assert
  # that the changeset bounding box is +bbox+.
  def check_changeset_modify(bbox)
    basic_authorization("test@openstreetmap.org", "test");  

    # create a new changeset for this operation, so we are assured
    # that the bounding box will be newly-generated.
    changeset_id = with_controller(ChangesetController.new) do
      content "<osm><changeset/></osm>"
      put :create
      assert_response :success, "couldn't create changeset for modify test"
      @response.body.to_i
    end

    # go back to the block to do the actual modifies
    yield changeset_id

    # now download the changeset to check its bounding box
    with_controller(ChangesetController.new) do
      get :read, :id => changeset_id
      assert_response :success, "can't re-read changeset for modify test"
      assert_select "osm>changeset", 1
      assert_select "osm>changeset[id=#{changeset_id}]", 1
      assert_select "osm>changeset[min_lon=#{bbox[0].to_f}]", 1
      assert_select "osm>changeset[min_lat=#{bbox[1].to_f}]", 1
      assert_select "osm>changeset[max_lon=#{bbox[2].to_f}]", 1
      assert_select "osm>changeset[max_lat=#{bbox[3].to_f}]", 1
    end
  end

  ##
  # update the changeset_id of a node element
  def update_changeset(xml, changeset_id)
    xml_attr_rewrite(xml, 'changeset', changeset_id)
  end

  ##
  # update an attribute in the node element
  def xml_attr_rewrite(xml, name, value)
    xml.find("//osm/relation").first[name] = value.to_s
    return xml
  end

  ##
  # parse some xml
  def xml_parse(xml)
    parser = XML::Parser.string(xml)
    parser.parse
  end
end
