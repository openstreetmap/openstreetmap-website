require File.dirname(__FILE__) + '/../test_helper'
require 'relation_controller'

class RelationControllerTest < ActionController::TestCase
  api_fixtures

  def basic_authorization(user, pass)
    @request.env["HTTP_AUTHORIZATION"] = "Basic %s" % Base64.encode64("#{user}:#{pass}")
  end

  def content(c)
    @request.env["RAW_POST_DATA"] = c.to_s
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


    # create an relation with a node as member
    nid = current_nodes(:used_node_1).id
    content "<osm><relation changeset='#{changeset_id}'>" +
      "<member type='node' ref='#{nid}' role='some'/>" +
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
    assert_response :conflict

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
    parser = XML::Parser.new
    parser.string = xml
    parser.parse
  end
end
