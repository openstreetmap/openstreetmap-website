require File.dirname(__FILE__) + '/../test_helper'
require 'relation_controller'

class RelationControllerTest < ActionController::TestCase
  api_fixtures

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/relation/create", :method => :put },
      { :controller => "relation", :action => "create" }
    )
    assert_routing(
      { :path => "/api/0.6/relation/1/full", :method => :get },
      { :controller => "relation", :action => "full", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/relation/1", :method => :get },
      { :controller => "relation", :action => "read", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/relation/1", :method => :put },
      { :controller => "relation", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/relation/1", :method => :delete },
      { :controller => "relation", :action => "delete", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/relations", :method => :get },
      { :controller => "relation", :action => "relations" }
    )

    assert_routing(
      { :path => "/api/0.6/node/1/relations", :method => :get },
      { :controller => "relation", :action => "relations_for_node", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/way/1/relations", :method => :get },
      { :controller => "relation", :action => "relations_for_way", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/relation/1/relations", :method => :get },
      { :controller => "relation", :action => "relations_for_relation", :id => "1" }
    )
  end

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
    basic_authorization users(:normal_user).email, "test"
    
    # put the relation in a dummy fixture changset
    changeset_id = changesets(:normal_user_first_change).id

    # create an relation without members
    content "<osm><relation changeset='#{changeset_id}'><tag k='test' v='yes' /></relation></osm>"
    put :create
    # hope for forbidden, due to user
    assert_response :forbidden, 
    "relation upload should have failed with forbidden"

    ###
    # create an relation with a node as member
    # This time try with a role attribute in the relation
    nid = current_nodes(:used_node_1).id
    content "<osm><relation changeset='#{changeset_id}'>" +
      "<member  ref='#{nid}' type='node' role='some'/>" +
      "<tag k='test' v='yes' /></relation></osm>"
    put :create
    # hope for forbidden due to user
    assert_response :forbidden, 
    "relation upload did not return forbidden status"
    
    ###
    # create an relation with a node as member, this time test that we don't 
    # need a role attribute to be included
    nid = current_nodes(:used_node_1).id
    content "<osm><relation changeset='#{changeset_id}'>" +
      "<member  ref='#{nid}' type='node'/>"+
      "<tag k='test' v='yes' /></relation></osm>"
    put :create
    # hope for forbidden due to user
    assert_response :forbidden, 
    "relation upload did not return forbidden status"

    ###
    # create an relation with a way and a node as members
    nid = current_nodes(:used_node_1).id
    wid = current_ways(:used_way).id
    content "<osm><relation changeset='#{changeset_id}'>" +
      "<member type='node' ref='#{nid}' role='some'/>" +
      "<member type='way' ref='#{wid}' role='other'/>" +
      "<tag k='test' v='yes' /></relation></osm>"
    put :create
    # hope for forbidden, due to user
    assert_response :forbidden, 
        "relation upload did not return success status"



    ## Now try with the public user
    basic_authorization users(:public_user).email, "test"
    
    # put the relation in a dummy fixture changset
    changeset_id = changesets(:public_user_first_change).id

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
    assert_equal users(:public_user).id, checkrelation.changeset.user_id, 
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
    assert_equal users(:public_user).id, checkrelation.changeset.user_id, 
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
    assert_equal users(:public_user).id, checkrelation.changeset.user_id, 
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
    assert_equal users(:public_user).id, checkrelation.changeset.user_id, 
        "saved relation does not belong to user that created it"
    assert_equal true, checkrelation.visible, 
        "saved relation is not visible"
    # ok the relation is there but can we also retrieve it?
    get :read, :id => relationid
    assert_response :success

  end

  # ------------------------------------
  # Test updating relations
  # ------------------------------------

  ##
  # test that, when tags are updated on a relation, the correct things
  # happen to the correct tables and the API gives sensible results. 
  # this is to test a case that gregory marler noticed and posted to
  # josm-dev.
  ## FIXME Move this to an integration test
  def test_update_relation_tags
    basic_authorization "test@example.com", "test"
    rel_id = current_relations(:multi_tag_relation).id
    cs_id = changesets(:public_user_first_change).id

    with_relation(rel_id) do |rel|
      # alter one of the tags
      tag = rel.find("//osm/relation/tag").first
      tag['v'] = 'some changed value'
      update_changeset(rel, cs_id)

      # check that the downloaded tags are the same as the uploaded tags...
      new_version = with_update(rel) do |new_rel|
        assert_tags_equal rel, new_rel
      end

      # check the original one in the current_* table again
      with_relation(rel_id) { |r| assert_tags_equal rel, r }

      # now check the version in the history
      with_relation(rel_id, new_version) { |r| assert_tags_equal rel, r }
    end
  end

  ##
  # test that, when tags are updated on a relation when using the diff
  # upload function, the correct things happen to the correct tables 
  # and the API gives sensible results. this is to test a case that 
  # gregory marler noticed and posted to josm-dev.
  def test_update_relation_tags_via_upload
    basic_authorization users(:public_user).email, "test"
    rel_id = current_relations(:multi_tag_relation).id
    cs_id = changesets(:public_user_first_change).id

    with_relation(rel_id) do |rel|
      # alter one of the tags
      tag = rel.find("//osm/relation/tag").first
      tag['v'] = 'some changed value'
      update_changeset(rel, cs_id)

      # check that the downloaded tags are the same as the uploaded tags...
      new_version = with_update_diff(rel) do |new_rel|
        assert_tags_equal rel, new_rel
      end

      # check the original one in the current_* table again
      with_relation(rel_id) { |r| assert_tags_equal rel, r }

      # now check the version in the history
      with_relation(rel_id, new_version) { |r| assert_tags_equal rel, r }
    end
  end

  # -------------------------------------
  # Test creating some invalid relations.
  # -------------------------------------

  def test_create_invalid
    basic_authorization users(:public_user).email, "test"

    # put the relation in a dummy fixture changset
    changeset_id = changesets(:public_user_first_change).id

    # create a relation with non-existing node as member
    content "<osm><relation changeset='#{changeset_id}'>" +
      "<member type='node' ref='0'/><tag k='test' v='yes' />" +
      "</relation></osm>"
    put :create
    # expect failure
    assert_response :precondition_failed, 
        "relation upload with invalid node did not return 'precondition failed'"
    assert_equal "Precondition failed: Relation with id  cannot be saved due to Node with id 0", @response.body
  end

  # -------------------------------------
  # Test creating a relation, with some invalid XML
  # -------------------------------------
  def test_create_invalid_xml
    basic_authorization users(:public_user).email, "test"
    
    # put the relation in a dummy fixture changeset that works
    changeset_id = changesets(:public_user_first_change).id
    
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
    ## First try to delete relation without auth
    delete :delete, :id => current_relations(:visible_relation).id
    assert_response :unauthorized
    
    
    ## Then try with the private user, to make sure that you get a forbidden
    basic_authorization(users(:normal_user).email, "test")
    
    # this shouldn't work, as we should need the payload...
    delete :delete, :id => current_relations(:visible_relation).id
    assert_response :forbidden

    # try to delete without specifying a changeset
    content "<osm><relation id='#{current_relations(:visible_relation).id}'/></osm>"
    delete :delete, :id => current_relations(:visible_relation).id
    assert_response :forbidden

    # try to delete with an invalid (closed) changeset
    content update_changeset(current_relations(:visible_relation).to_xml,
                             changesets(:normal_user_closed_change).id)
    delete :delete, :id => current_relations(:visible_relation).id
    assert_response :forbidden

    # try to delete with an invalid (non-existent) changeset
    content update_changeset(current_relations(:visible_relation).to_xml,0)
    delete :delete, :id => current_relations(:visible_relation).id
    assert_response :forbidden

    # this won't work because the relation is in-use by another relation
    content(relations(:used_relation).to_xml)
    delete :delete, :id => current_relations(:used_relation).id
    assert_response :forbidden

    # this should work when we provide the appropriate payload...
    content(relations(:visible_relation).to_xml)
    delete :delete, :id => current_relations(:visible_relation).id
    assert_response :forbidden

    # this won't work since the relation is already deleted
    content(relations(:invisible_relation).to_xml)
    delete :delete, :id => current_relations(:invisible_relation).id
    assert_response :forbidden

    # this works now because the relation which was using this one 
    # has been deleted.
    content(relations(:used_relation).to_xml)
    delete :delete, :id => current_relations(:used_relation).id
    assert_response :forbidden

    # this won't work since the relation never existed
    delete :delete, :id => 0
    assert_response :forbidden

    

    ## now set auth for the public user
    basic_authorization(users(:public_user).email, "test");  

    # this shouldn't work, as we should need the payload...
    delete :delete, :id => current_relations(:visible_relation).id
    assert_response :bad_request

    # try to delete without specifying a changeset
    content "<osm><relation id='#{current_relations(:visible_relation).id}' version='#{current_relations(:visible_relation).version}' /></osm>"
    delete :delete, :id => current_relations(:visible_relation).id
    assert_response :bad_request
    assert_match(/Changeset id is missing/, @response.body)

    # try to delete with an invalid (closed) changeset
    content update_changeset(current_relations(:visible_relation).to_xml,
                             changesets(:normal_user_closed_change).id)
    delete :delete, :id => current_relations(:visible_relation).id
    assert_response :conflict

    # try to delete with an invalid (non-existent) changeset
    content update_changeset(current_relations(:visible_relation).to_xml,0)
    delete :delete, :id => current_relations(:visible_relation).id
    assert_response :conflict

    # this won't work because the relation is in a changeset owned by someone else
    content(relations(:used_relation).to_xml)
    delete :delete, :id => current_relations(:used_relation).id
    assert_response :conflict, 
    "shouldn't be able to delete a relation in a changeset owned by someone else (#{@response.body})"

    # this won't work because the relation in the payload is different to that passed
    content(relations(:public_used_relation).to_xml)
    delete :delete, :id => current_relations(:used_relation).id
    assert_not_equal relations(:public_used_relation).id, current_relations(:used_relation).id
    assert_response :bad_request, "shouldn't be able to delete a relation when payload is different to the url"
    
    # this won't work because the relation is in-use by another relation
    content(relations(:public_used_relation).to_xml)
    delete :delete, :id => current_relations(:public_used_relation).id
    assert_response :precondition_failed, 
       "shouldn't be able to delete a relation used in a relation (#{@response.body})"
    assert_equal "Precondition failed: The relation 5 is used in relation 6.", @response.body

    # this should work when we provide the appropriate payload...
    content(relations(:multi_tag_relation).to_xml)
    delete :delete, :id => current_relations(:multi_tag_relation).id
    assert_response :success

    # valid delete should return the new version number, which should
    # be greater than the old version number
    assert @response.body.to_i > current_relations(:visible_relation).version,
       "delete request should return a new version number for relation"

    # this won't work since the relation is already deleted
    content(relations(:invisible_relation).to_xml)
    delete :delete, :id => current_relations(:invisible_relation).id
    assert_response :gone
    
    # Public visible relation needs to be deleted
    content(relations(:public_visible_relation).to_xml)
    delete :delete, :id => current_relations(:public_visible_relation).id
    assert_response :success

    # this works now because the relation which was using this one 
    # has been deleted.
    content(relations(:public_used_relation).to_xml)
    delete :delete, :id => current_relations(:public_used_relation).id
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
    check_changeset_modify(BoundingBox.new(3,3,5,5)) do |changeset_id|
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
    relation_id = current_relations(:visible_relation).id

    [current_nodes(:used_node_1),
     current_nodes(:used_node_2),
     current_ways(:used_way),
     current_ways(:way_with_versions)
    ].each_with_index do |element, version|
      bbox = element.bbox.to_unscaled
      check_changeset_modify(bbox) do |changeset_id|
        relation_xml = Relation.find(relation_id).to_xml
        relation_element = relation_xml.find("//osm/relation").first
        new_member = XML::Node.new("member")
        new_member['ref'] = element.id.to_s
        new_member['type'] = element.class.to_s.downcase
        new_member['role'] = "some_role"
        relation_element << new_member
      
        # update changeset ID to point to new changeset
        update_changeset(relation_xml, changeset_id)
      
        # upload the change
        content relation_xml
        put :update, :id => current_relations(:visible_relation).id
        assert_response :success, "can't update relation for add #{element.class}/bbox test: #{@response.body}"

        # get it back and check the ordering 
        get :read, :id => relation_id
        assert_response :success, "can't read back the relation: #{@response.body}"
        check_ordering(relation_xml, @response.body)
      end
    end
  end
  
  ##
  # remove a member from a relation and check the bounding box is 
  # only that element.
  def test_remove_member_bounding_box
    check_changeset_modify(BoundingBox.new(5,5,5,5)) do |changeset_id|
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
    basic_authorization(users(:public_user).email, "test")
    
    doc_str = <<OSM
<osm>
 <relation changeset='4'>
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

    # check the ordering in the history tables:
    with_controller(OldRelationController.new) do
      get :version, :id => relation_id, :version => 2
      assert_response :success, "can't read back version 2 of the relation #{relation_id}"
      check_ordering(doc, @response.body)
    end
  end

  ## 
  # check that relations can contain duplicate members
  def test_relation_member_duplicates
    doc_str = <<OSM
<osm>
 <relation changeset='4'>
  <member ref='1' type='node' role='forward'/>
  <member ref='3' type='node' role='forward'/>
  <member ref='1' type='node' role='forward'/>
  <member ref='3' type='node' role='forward'/>
 </relation>
</osm>
OSM
    doc = XML::Parser.string(doc_str).parse

    ## First try with the private user
    basic_authorization(users(:normal_user).email, "test");  

    content doc
    put :create
    assert_response :forbidden

    ## Now try with the public user
    basic_authorization(users(:public_user).email, "test");  

    content doc
    put :create
    assert_response :success, "can't create a relation: #{@response.body}"
    relation_id = @response.body.to_i

    # get it back and check the ordering
    get :read, :id => relation_id
    assert_response :success, "can't read back the relation: #{relation_id}"
    check_ordering(doc, @response.body)
  end

  ##
  # test that the ordering of elements in the history is the same as in current.
  def test_history_ordering
    doc_str = <<OSM
<osm>
 <relation changeset='4'>
  <member ref='1' type='node' role='forward'/>
  <member ref='5' type='node' role='forward'/>
  <member ref='4' type='node' role='forward'/>
  <member ref='3' type='node' role='forward'/>
 </relation>
</osm>
OSM
    doc = XML::Parser.string(doc_str).parse
    basic_authorization(users(:public_user).email, "test");  

    content doc
    put :create
    assert_response :success, "can't create a relation: #{@response.body}"
    relation_id = @response.body.to_i

    # check the ordering in the current tables:
    get :read, :id => relation_id
    assert_response :success, "can't read back the relation: #{@response.body}"
    check_ordering(doc, @response.body)

    # check the ordering in the history tables:
    with_controller(OldRelationController.new) do
      get :version, :id => relation_id, :version => 1
      assert_response :success, "can't read back version 1 of the relation: #{@response.body}"
      check_ordering(doc, @response.body)
    end
  end

  ##
  # remove all the members from a relation. the result is pretty useless, but
  # still technically valid.
  def test_remove_all_members 
    check_changeset_modify(BoundingBox.new(3,3,5,5)) do |changeset_id|
      relation_xml = current_relations(:visible_relation).to_xml
      relation_xml.
        find("//osm/relation/member").
        each {|m| m.remove!}
      
      # update changeset ID to point to new changeset
      update_changeset(relation_xml, changeset_id)
      
      # upload the change
      content relation_xml
      put :update, :id => current_relations(:visible_relation).id
      assert_response :success, "can't update relation for remove all members test"
      checkrelation = Relation.find(current_relations(:visible_relation).id)
      assert_not_nil(checkrelation, 
                     "uploaded relation not found in database after upload")
      assert_equal(0, checkrelation.members.length,
                   "relation contains members but they should have all been deleted")
    end
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
    ## First test with the private user to check that you get a forbidden
    basic_authorization(users(:normal_user).email, "test");  

    # create a new changeset for this operation, so we are assured
    # that the bounding box will be newly-generated.
    changeset_id = with_controller(ChangesetController.new) do
      content "<osm><changeset/></osm>"
      put :create
      assert_response :forbidden, "shouldn't be able to create changeset for modify test, as should get forbidden"
    end

    
    ## Now do the whole thing with the public user
    basic_authorization(users(:public_user).email, "test")
    
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
      assert_select "osm>changeset", 1, "Changeset element doesn't exist in #{@response.body}"
      assert_select "osm>changeset[id=#{changeset_id}]", 1, "Changeset id=#{changeset_id} doesn't exist in #{@response.body}"
      assert_select "osm>changeset[min_lon=#{bbox.min_lon}]", 1, "Changeset min_lon wrong in #{@response.body}"
      assert_select "osm>changeset[min_lat=#{bbox.min_lat}]", 1, "Changeset min_lat wrong in #{@response.body}"
      assert_select "osm>changeset[max_lon=#{bbox.max_lon}]", 1, "Changeset max_lon wrong in #{@response.body}"
      assert_select "osm>changeset[max_lat=#{bbox.max_lat}]", 1, "Changeset max_lat wrong in #{@response.body}"
    end
  end

  ##
  # yields the relation with the given +id+ (and optional +version+
  # to read from the history tables) into the block. the parsed XML
  # doc is returned.
  def with_relation(id, ver = nil)
    if ver.nil?
      get :read, :id => id
    else
      with_controller(OldRelationController.new) do
        get :version, :id => id, :version => ver
      end
    end
    assert_response :success
    yield xml_parse(@response.body)
  end

  ##
  # updates the relation (XML) +rel+ and 
  # yields the new version of that relation into the block. 
  # the parsed XML doc is retured.
  def with_update(rel)
    rel_id = rel.find("//osm/relation").first["id"].to_i
    content rel
    put :update, :id => rel_id
    assert_response :success, "can't update relation: #{@response.body}"
    version = @response.body.to_i

    # now get the new version
    get :read, :id => rel_id
    assert_response :success
    new_rel = xml_parse(@response.body)

    yield new_rel

    return version
  end

  ##
  # updates the relation (XML) +rel+ via the diff-upload API and
  # yields the new version of that relation into the block. 
  # the parsed XML doc is retured.
  def with_update_diff(rel)
    rel_id = rel.find("//osm/relation").first["id"].to_i
    cs_id = rel.find("//osm/relation").first['changeset'].to_i
    version = nil

    with_controller(ChangesetController.new) do
      doc = OSM::API.new.get_xml_doc
      change = XML::Node.new 'osmChange'
      doc.root = change
      modify = XML::Node.new 'modify'
      change << modify
      modify << doc.import(rel.find("//osm/relation").first)

      content doc.to_s
      post :upload, :id => cs_id
      assert_response :success, "can't upload diff relation: #{@response.body}"
      version = xml_parse(@response.body).find("//diffResult/relation").first["new_version"].to_i
    end      
    
    # now get the new version
    get :read, :id => rel_id
    assert_response :success
    new_rel = xml_parse(@response.body)
    
    yield new_rel
    
    return version
  end

  ##
  # returns a k->v hash of tags from an xml doc
  def get_tags_as_hash(a) 
    a.find("//osm/relation/tag").sort_by { |v| v['k'] }.inject({}) do |h,v|
      h[v['k']] = v['v']
      h
    end
  end
  
  ##
  # assert that all tags on relation documents +a+ and +b+ 
  # are equal
  def assert_tags_equal(a, b)
    # turn the XML doc into tags hashes
    a_tags = get_tags_as_hash(a)
    b_tags = get_tags_as_hash(b)

    assert_equal a_tags.keys, b_tags.keys, "Tag keys should be identical."
    a_tags.each do |k, v|
      assert_equal v, b_tags[k], 
        "Tags which were not altered should be the same. " +
        "#{a_tags.inspect} != #{b_tags.inspect}"
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
