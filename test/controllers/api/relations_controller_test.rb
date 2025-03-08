require "test_helper"

module Api
  class RelationsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/relations", :method => :get },
        { :controller => "api/relations", :action => "index" }
      )
      assert_routing(
        { :path => "/api/0.6/relations.json", :method => :get },
        { :controller => "api/relations", :action => "index", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/relations", :method => :post },
        { :controller => "api/relations", :action => "create" }
      )
      assert_routing(
        { :path => "/api/0.6/relation/1", :method => :get },
        { :controller => "api/relations", :action => "show", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/relation/1.json", :method => :get },
        { :controller => "api/relations", :action => "show", :id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/relation/1/full", :method => :get },
        { :controller => "api/relations", :action => "show", :full => true, :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/relation/1/full.json", :method => :get },
        { :controller => "api/relations", :action => "show", :full => true, :id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/relation/1", :method => :put },
        { :controller => "api/relations", :action => "update", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/relation/1", :method => :delete },
        { :controller => "api/relations", :action => "destroy", :id => "1" }
      )

      assert_recognizes(
        { :controller => "api/relations", :action => "create" },
        { :path => "/api/0.6/relation/create", :method => :put }
      )
    end

    ##
    # test fetching multiple relations
    def test_index
      relation1 = create(:relation)
      relation2 = create(:relation, :deleted)
      relation3 = create(:relation, :with_history, :version => 2)
      relation4 = create(:relation, :with_history, :version => 2)
      relation4.old_relations.find_by(:version => 1).redact!(create(:redaction))

      # check error when no parameter provided
      get api_relations_path
      assert_response :bad_request

      # check error when no parameter value provided
      get api_relations_path(:relations => "")
      assert_response :bad_request

      # test a working call
      get api_relations_path(:relations => "#{relation1.id},#{relation2.id},#{relation3.id},#{relation4.id}")
      assert_response :success
      assert_select "osm" do
        assert_select "relation", :count => 4
        assert_select "relation[id='#{relation1.id}'][visible='true']", :count => 1
        assert_select "relation[id='#{relation2.id}'][visible='false']", :count => 1
        assert_select "relation[id='#{relation3.id}'][visible='true']", :count => 1
        assert_select "relation[id='#{relation4.id}'][visible='true']", :count => 1
      end

      # test a working call with json format
      get api_relations_path(:relations => "#{relation1.id},#{relation2.id},#{relation3.id},#{relation4.id}", :format => "json")

      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 4, js["elements"].count
      assert_equal 4, (js["elements"].count { |a| a["type"] == "relation" })
      assert_equal 1, (js["elements"].count { |a| a["id"] == relation1.id && a["visible"].nil? })
      assert_equal 1, (js["elements"].count { |a| a["id"] == relation2.id && a["visible"] == false })
      assert_equal 1, (js["elements"].count { |a| a["id"] == relation3.id && a["visible"].nil? })
      assert_equal 1, (js["elements"].count { |a| a["id"] == relation4.id && a["visible"].nil? })

      # check error when a non-existent relation is included
      get api_relations_path(:relations => "#{relation1.id},#{relation2.id},#{relation3.id},#{relation4.id},0")
      assert_response :not_found
    end

    # -------------------------------------
    # Test showing relations.
    # -------------------------------------

    def test_show_not_found
      get api_relation_path(0)
      assert_response :not_found
    end

    def test_show_deleted
      get api_relation_path(create(:relation, :deleted))
      assert_response :gone
    end

    def test_show
      relation = create(:relation, :timestamp => "2021-02-03T00:00:00Z")
      node = create(:node, :timestamp => "2021-04-05T00:00:00Z")
      create(:relation_member, :relation => relation, :member => node)

      get api_relation_path(relation)

      assert_response :success
      assert_not_nil @response.header["Last-Modified"]
      assert_equal "2021-02-03T00:00:00Z", Time.parse(@response.header["Last-Modified"]).utc.xmlschema
      assert_dom "node", :count => 0
      assert_dom "relation", :count => 1 do
        assert_dom "> @id", :text => relation.id.to_s
      end
    end

    def test_full_not_found
      get api_relation_path(999999, :full => true)
      assert_response :not_found
    end

    def test_full_deleted
      get api_relation_path(create(:relation, :deleted), :full => true)
      assert_response :gone
    end

    def test_full_empty
      relation = create(:relation)

      get api_relation_path(relation, :full => true)

      assert_response :success
      assert_dom "relation", :count => 1 do
        assert_dom "> @id", :text => relation.id.to_s
      end
    end

    def test_full_with_node_member
      relation = create(:relation)
      node = create(:node)
      create(:relation_member, :relation => relation, :member => node)

      get api_relation_path(relation, :full => true)

      assert_response :success
      assert_dom "node", :count => 1 do
        assert_dom "> @id", :text => node.id.to_s
      end
      assert_dom "relation", :count => 1 do
        assert_dom "> @id", :text => relation.id.to_s
      end
    end

    def test_full_with_way_member
      relation = create(:relation)
      way = create(:way_with_nodes)
      create(:relation_member, :relation => relation, :member => way)

      get api_relation_path(relation, :full => true)

      assert_response :success
      assert_dom "node", :count => 1 do
        assert_dom "> @id", :text => way.nodes[0].id.to_s
      end
      assert_dom "way", :count => 1 do
        assert_dom "> @id", :text => way.id.to_s
      end
      assert_dom "relation", :count => 1 do
        assert_dom "> @id", :text => relation.id.to_s
      end
    end

    def test_full_with_node_member_json
      relation = create(:relation)
      node = create(:node)
      create(:relation_member, :relation => relation, :member => node)

      get api_relation_path(relation, :full => true, :format => "json")

      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 2, js["elements"].count

      js_relations = js["elements"].filter { |e| e["type"] == "relation" }
      assert_equal 1, js_relations.count
      assert_equal relation.id, js_relations[0]["id"]
      assert_equal 1, js_relations[0]["members"].count
      assert_equal "node", js_relations[0]["members"][0]["type"]
      assert_equal node.id, js_relations[0]["members"][0]["ref"]

      js_nodes = js["elements"].filter { |e| e["type"] == "node" }
      assert_equal 1, js_nodes.count
      assert_equal node.id, js_nodes[0]["id"]
    end

    # -------------------------------------
    # Test simple relation creation.
    # -------------------------------------

    def test_create
      private_user = create(:user, :data_public => false)
      private_changeset = create(:changeset, :user => private_user)
      user = create(:user)
      changeset = create(:changeset, :user => user)
      node = create(:node)
      way = create(:way_with_nodes, :nodes_count => 2)

      auth_header = bearer_authorization_header private_user

      # create an relation without members
      xml = "<osm><relation changeset='#{private_changeset.id}'><tag k='test' v='yes' /></relation></osm>"
      post api_relations_path, :params => xml, :headers => auth_header
      # hope for forbidden, due to user
      assert_response :forbidden,
                      "relation upload should have failed with forbidden"

      ###
      # create an relation with a node as member
      # This time try with a role attribute in the relation
      xml = "<osm><relation changeset='#{private_changeset.id}'>" \
            "<member  ref='#{node.id}' type='node' role='some'/>" \
            "<tag k='test' v='yes' /></relation></osm>"
      post api_relations_path, :params => xml, :headers => auth_header
      # hope for forbidden due to user
      assert_response :forbidden,
                      "relation upload did not return forbidden status"

      ###
      # create an relation with a node as member, this time test that we don't
      # need a role attribute to be included
      xml = "<osm><relation changeset='#{private_changeset.id}'>" \
            "<member  ref='#{node.id}' type='node'/><tag k='test' v='yes' /></relation></osm>"
      post api_relations_path, :params => xml, :headers => auth_header
      # hope for forbidden due to user
      assert_response :forbidden,
                      "relation upload did not return forbidden status"

      ###
      # create an relation with a way and a node as members
      xml = "<osm><relation changeset='#{private_changeset.id}'>" \
            "<member type='node' ref='#{node.id}' role='some'/>" \
            "<member type='way' ref='#{way.id}' role='other'/>" \
            "<tag k='test' v='yes' /></relation></osm>"
      post api_relations_path, :params => xml, :headers => auth_header
      # hope for forbidden, due to user
      assert_response :forbidden,
                      "relation upload did not return success status"

      ## Now try with the public user
      auth_header = bearer_authorization_header user

      # create an relation without members
      xml = "<osm><relation changeset='#{changeset.id}'><tag k='test' v='yes' /></relation></osm>"
      post api_relations_path, :params => xml, :headers => auth_header
      # hope for success
      assert_response :success,
                      "relation upload did not return success status"
      # read id of created relation and search for it
      relationid = @response.body
      checkrelation = Relation.find(relationid)
      assert_not_nil checkrelation,
                     "uploaded relation not found in data base after upload"
      # compare values
      assert_equal(0, checkrelation.members.length, "saved relation contains members but should not")
      assert_equal(1, checkrelation.tags.length, "saved relation does not contain exactly one tag")
      assert_equal changeset.id, checkrelation.changeset.id,
                   "saved relation does not belong in the changeset it was assigned to"
      assert_equal user.id, checkrelation.changeset.user_id,
                   "saved relation does not belong to user that created it"
      assert checkrelation.visible,
             "saved relation is not visible"
      # ok the relation is there but can we also retrieve it?
      get api_relation_path(relationid)
      assert_response :success

      ###
      # create an relation with a node as member
      # This time try with a role attribute in the relation
      xml = "<osm><relation changeset='#{changeset.id}'>" \
            "<member  ref='#{node.id}' type='node' role='some'/>" \
            "<tag k='test' v='yes' /></relation></osm>"
      post api_relations_path, :params => xml, :headers => auth_header
      # hope for success
      assert_response :success,
                      "relation upload did not return success status"
      # read id of created relation and search for it
      relationid = @response.body
      checkrelation = Relation.find(relationid)
      assert_not_nil checkrelation,
                     "uploaded relation not found in data base after upload"
      # compare values
      assert_equal(1, checkrelation.members.length, "saved relation does not contain exactly one member")
      assert_equal(1, checkrelation.tags.length, "saved relation does not contain exactly one tag")
      assert_equal changeset.id, checkrelation.changeset.id,
                   "saved relation does not belong in the changeset it was assigned to"
      assert_equal user.id, checkrelation.changeset.user_id,
                   "saved relation does not belong to user that created it"
      assert checkrelation.visible,
             "saved relation is not visible"
      # ok the relation is there but can we also retrieve it?

      get api_relation_path(relationid)
      assert_response :success

      ###
      # create an relation with a node as member, this time test that we don't
      # need a role attribute to be included
      xml = "<osm><relation changeset='#{changeset.id}'>" \
            "<member  ref='#{node.id}' type='node'/><tag k='test' v='yes' /></relation></osm>"
      post api_relations_path, :params => xml, :headers => auth_header
      # hope for success
      assert_response :success,
                      "relation upload did not return success status"
      # read id of created relation and search for it
      relationid = @response.body
      checkrelation = Relation.find(relationid)
      assert_not_nil checkrelation,
                     "uploaded relation not found in data base after upload"
      # compare values
      assert_equal(1, checkrelation.members.length, "saved relation does not contain exactly one member")
      assert_equal(1, checkrelation.tags.length, "saved relation does not contain exactly one tag")
      assert_equal changeset.id, checkrelation.changeset.id,
                   "saved relation does not belong in the changeset it was assigned to"
      assert_equal user.id, checkrelation.changeset.user_id,
                   "saved relation does not belong to user that created it"
      assert checkrelation.visible,
             "saved relation is not visible"
      # ok the relation is there but can we also retrieve it?

      get api_relation_path(relationid)
      assert_response :success

      ###
      # create an relation with a way and a node as members
      xml = "<osm><relation changeset='#{changeset.id}'>" \
            "<member type='node' ref='#{node.id}' role='some'/>" \
            "<member type='way' ref='#{way.id}' role='other'/>" \
            "<tag k='test' v='yes' /></relation></osm>"
      post api_relations_path, :params => xml, :headers => auth_header
      # hope for success
      assert_response :success,
                      "relation upload did not return success status"
      # read id of created relation and search for it
      relationid = @response.body
      checkrelation = Relation.find(relationid)
      assert_not_nil checkrelation,
                     "uploaded relation not found in data base after upload"
      # compare values
      assert_equal(2, checkrelation.members.length, "saved relation does not have exactly two members")
      assert_equal(1, checkrelation.tags.length, "saved relation does not contain exactly one tag")
      assert_equal changeset.id, checkrelation.changeset.id,
                   "saved relation does not belong in the changeset it was assigned to"
      assert_equal user.id, checkrelation.changeset.user_id,
                   "saved relation does not belong to user that created it"
      assert checkrelation.visible,
             "saved relation is not visible"
      # ok the relation is there but can we also retrieve it?
      get api_relation_path(relationid)
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
      user = create(:user)
      changeset = create(:changeset, :user => user)
      relation = create(:relation)
      create_list(:relation_tag, 4, :relation => relation)

      auth_header = bearer_authorization_header user

      with_relation(relation.id) do |rel|
        # alter one of the tags
        tag = rel.find("//osm/relation/tag").first
        tag["v"] = "some changed value"
        update_changeset(rel, changeset.id)

        # check that the downloaded tags are the same as the uploaded tags...
        new_version = with_update(rel, auth_header) do |new_rel|
          assert_tags_equal rel, new_rel
        end

        # check the original one in the current_* table again
        with_relation(relation.id) { |r| assert_tags_equal rel, r }

        # now check the version in the history
        with_relation(relation.id, new_version) { |r| assert_tags_equal rel, r }
      end
    end

    ##
    # test that, when tags are updated on a relation when using the diff
    # upload function, the correct things happen to the correct tables
    # and the API gives sensible results. this is to test a case that
    # gregory marler noticed and posted to josm-dev.
    def test_update_relation_tags_via_upload
      user = create(:user)
      changeset = create(:changeset, :user => user)
      relation = create(:relation)
      create_list(:relation_tag, 4, :relation => relation)

      auth_header = bearer_authorization_header user

      with_relation(relation.id) do |rel|
        # alter one of the tags
        tag = rel.find("//osm/relation/tag").first
        tag["v"] = "some changed value"
        update_changeset(rel, changeset.id)

        # check that the downloaded tags are the same as the uploaded tags...
        new_version = with_update_diff(rel, auth_header) do |new_rel|
          assert_tags_equal rel, new_rel
        end

        # check the original one in the current_* table again
        with_relation(relation.id) { |r| assert_tags_equal rel, r }

        # now check the version in the history
        with_relation(relation.id, new_version) { |r| assert_tags_equal rel, r }
      end
    end

    def test_update_wrong_id
      user = create(:user)
      changeset = create(:changeset, :user => user)
      relation = create(:relation)
      other_relation = create(:relation)

      auth_header = bearer_authorization_header user
      with_relation(relation.id) do |rel|
        update_changeset(rel, changeset.id)
        put api_relation_path(other_relation), :params => rel.to_s, :headers => auth_header
        assert_response :bad_request
      end
    end

    # -------------------------------------
    # Test creating some invalid relations.
    # -------------------------------------

    def test_create_invalid
      user = create(:user)
      changeset = create(:changeset, :user => user)

      auth_header = bearer_authorization_header user

      # create a relation with non-existing node as member
      xml = "<osm><relation changeset='#{changeset.id}'>" \
            "<member type='node' ref='0'/><tag k='test' v='yes' />" \
            "</relation></osm>"
      post api_relations_path, :params => xml, :headers => auth_header
      # expect failure
      assert_response :precondition_failed,
                      "relation upload with invalid node did not return 'precondition failed'"
      assert_equal "Precondition failed: Relation with id  cannot be saved due to Node with id 0", @response.body
    end

    # -------------------------------------
    # Test creating a relation, with some invalid XML
    # -------------------------------------
    def test_create_invalid_xml
      user = create(:user)
      changeset = create(:changeset, :user => user)
      node = create(:node)

      auth_header = bearer_authorization_header user

      # create some xml that should return an error
      xml = "<osm><relation changeset='#{changeset.id}'>" \
            "<member type='type' ref='#{node.id}' role=''/>" \
            "<tag k='tester' v='yep'/></relation></osm>"
      post api_relations_path, :params => xml, :headers => auth_header
      # expect failure
      assert_response :bad_request
      assert_match(/Cannot parse valid relation from xml string/, @response.body)
      assert_match(/The type is not allowed only, /, @response.body)
    end

    # -------------------------------------
    # Test deleting relations.
    # -------------------------------------

    def test_destroy
      private_user = create(:user, :data_public => false)
      private_user_closed_changeset = create(:changeset, :closed, :user => private_user)
      user = create(:user)
      closed_changeset = create(:changeset, :closed, :user => user)
      changeset = create(:changeset, :user => user)
      relation = create(:relation)
      used_relation = create(:relation)
      super_relation = create(:relation_member, :member => used_relation).relation
      deleted_relation = create(:relation, :deleted)
      multi_tag_relation = create(:relation)
      create_list(:relation_tag, 4, :relation => multi_tag_relation)

      ## First try to delete relation without auth
      delete api_relation_path(relation)
      assert_response :unauthorized

      ## Then try with the private user, to make sure that you get a forbidden
      auth_header = bearer_authorization_header private_user

      # this shouldn't work, as we should need the payload...
      delete api_relation_path(relation), :headers => auth_header
      assert_response :forbidden

      # try to delete without specifying a changeset
      xml = "<osm><relation id='#{relation.id}'/></osm>"
      delete api_relation_path(relation), :params => xml.to_s, :headers => auth_header
      assert_response :forbidden

      # try to delete with an invalid (closed) changeset
      xml = update_changeset(xml_for_relation(relation),
                             private_user_closed_changeset.id)
      delete api_relation_path(relation), :params => xml.to_s, :headers => auth_header
      assert_response :forbidden

      # try to delete with an invalid (non-existent) changeset
      xml = update_changeset(xml_for_relation(relation), 0)
      delete api_relation_path(relation), :params => xml.to_s, :headers => auth_header
      assert_response :forbidden

      # this won't work because the relation is in-use by another relation
      xml = xml_for_relation(used_relation)
      delete api_relation_path(used_relation), :params => xml.to_s, :headers => auth_header
      assert_response :forbidden

      # this should work when we provide the appropriate payload...
      xml = xml_for_relation(relation)
      delete api_relation_path(relation), :params => xml.to_s, :headers => auth_header
      assert_response :forbidden

      # this won't work since the relation is already deleted
      xml = xml_for_relation(deleted_relation)
      delete api_relation_path(deleted_relation), :params => xml.to_s, :headers => auth_header
      assert_response :forbidden

      # this won't work since the relation never existed
      delete api_relation_path(0), :headers => auth_header
      assert_response :forbidden

      ## now set auth for the public user
      auth_header = bearer_authorization_header user

      # this shouldn't work, as we should need the payload...
      delete api_relation_path(relation), :headers => auth_header
      assert_response :bad_request

      # try to delete without specifying a changeset
      xml = "<osm><relation id='#{relation.id}' version='#{relation.version}' /></osm>"
      delete api_relation_path(relation), :params => xml.to_s, :headers => auth_header
      assert_response :bad_request
      assert_match(/Changeset id is missing/, @response.body)

      # try to delete with an invalid (closed) changeset
      xml = update_changeset(xml_for_relation(relation),
                             closed_changeset.id)
      delete api_relation_path(relation), :params => xml.to_s, :headers => auth_header
      assert_response :conflict

      # try to delete with an invalid (non-existent) changeset
      xml = update_changeset(xml_for_relation(relation), 0)
      delete api_relation_path(relation), :params => xml.to_s, :headers => auth_header
      assert_response :conflict

      # this won't work because the relation is in a changeset owned by someone else
      xml = update_changeset(xml_for_relation(relation), create(:changeset).id)
      delete api_relation_path(relation), :params => xml.to_s, :headers => auth_header
      assert_response :conflict,
                      "shouldn't be able to delete a relation in a changeset owned by someone else (#{@response.body})"

      # this won't work because the relation in the payload is different to that passed
      xml = update_changeset(xml_for_relation(relation), changeset.id)
      delete api_relation_path(create(:relation)), :params => xml.to_s, :headers => auth_header
      assert_response :bad_request, "shouldn't be able to delete a relation when payload is different to the url"

      # this won't work because the relation is in-use by another relation
      xml = update_changeset(xml_for_relation(used_relation), changeset.id)
      delete api_relation_path(used_relation), :params => xml.to_s, :headers => auth_header
      assert_response :precondition_failed,
                      "shouldn't be able to delete a relation used in a relation (#{@response.body})"
      assert_equal "Precondition failed: The relation #{used_relation.id} is used in relation #{super_relation.id}.", @response.body

      # this should work when we provide the appropriate payload...
      xml = update_changeset(xml_for_relation(multi_tag_relation), changeset.id)
      delete api_relation_path(multi_tag_relation), :params => xml.to_s, :headers => auth_header
      assert_response :success

      # valid delete should return the new version number, which should
      # be greater than the old version number
      assert_operator @response.body.to_i, :>, multi_tag_relation.version, "delete request should return a new version number for relation"

      # this won't work since the relation is already deleted
      xml = update_changeset(xml_for_relation(deleted_relation), changeset.id)
      delete api_relation_path(deleted_relation), :params => xml.to_s, :headers => auth_header
      assert_response :gone

      # Public visible relation needs to be deleted
      xml = update_changeset(xml_for_relation(super_relation), changeset.id)
      delete api_relation_path(super_relation), :params => xml.to_s, :headers => auth_header
      assert_response :success

      # this works now because the relation which was using this one
      # has been deleted.
      xml = update_changeset(xml_for_relation(used_relation), changeset.id)
      delete api_relation_path(used_relation), :params => xml.to_s, :headers => auth_header
      assert_response :success,
                      "should be able to delete a relation used in an old relation (#{@response.body})"

      # this won't work since the relation never existed
      delete api_relation_path(0), :headers => auth_header
      assert_response :not_found
    end

    ##
    # when a relation's tag is modified then it should put the bounding
    # box of all its members into the changeset.
    def test_tag_modify_bounding_box
      relation = create(:relation)
      node1 = create(:node, :lat => 0.3, :lon => 0.3)
      node2 = create(:node, :lat => 0.5, :lon => 0.5)
      way = create(:way)
      create(:way_node, :way => way, :node => node1)
      create(:relation_member, :relation => relation, :member => way)
      create(:relation_member, :relation => relation, :member => node2)
      # the relation contains nodes1 and node2 (node1
      # indirectly via the way), so the bbox should be [0.3,0.3,0.5,0.5].
      check_changeset_modify(BoundingBox.new(0.3, 0.3, 0.5, 0.5)) do |changeset_id, auth_header|
        # add a tag to an existing relation
        relation_xml = xml_for_relation(relation)
        relation_element = relation_xml.find("//osm/relation").first
        new_tag = XML::Node.new("tag")
        new_tag["k"] = "some_new_tag"
        new_tag["v"] = "some_new_value"
        relation_element << new_tag

        # update changeset ID to point to new changeset
        update_changeset(relation_xml, changeset_id)

        # upload the change
        put api_relation_path(relation), :params => relation_xml.to_s, :headers => auth_header
        assert_response :success, "can't update relation for tag/bbox test"
      end
    end

    ##
    # add a member to a relation and check the bounding box is only that
    # element.
    def test_add_member_bounding_box
      relation = create(:relation)
      node1 = create(:node, :lat => 4, :lon => 4)
      node2 = create(:node, :lat => 7, :lon => 7)
      way1 = create(:way)
      create(:way_node, :way => way1, :node => create(:node, :lat => 8, :lon => 8))
      way2 = create(:way)
      create(:way_node, :way => way2, :node => create(:node, :lat => 9, :lon => 9), :sequence_id => 1)
      create(:way_node, :way => way2, :node => create(:node, :lat => 10, :lon => 10), :sequence_id => 2)

      [node1, node2, way1, way2].each do |element|
        bbox = element.bbox.to_unscaled
        check_changeset_modify(bbox) do |changeset_id, auth_header|
          relation_xml = xml_for_relation(Relation.find(relation.id))
          relation_element = relation_xml.find("//osm/relation").first
          new_member = XML::Node.new("member")
          new_member["ref"] = element.id.to_s
          new_member["type"] = element.class.to_s.downcase
          new_member["role"] = "some_role"
          relation_element << new_member

          # update changeset ID to point to new changeset
          update_changeset(relation_xml, changeset_id)

          # upload the change
          put api_relation_path(relation), :params => relation_xml.to_s, :headers => auth_header
          assert_response :success, "can't update relation for add #{element.class}/bbox test: #{@response.body}"

          # get it back and check the ordering
          get api_relation_path(relation)
          assert_response :success, "can't read back the relation: #{@response.body}"
          check_ordering(relation_xml, @response.body)
        end
      end
    end

    ##
    # remove a member from a relation and check the bounding box is
    # only that element.
    def test_remove_member_bounding_box
      relation = create(:relation)
      node1 = create(:node, :lat => 3, :lon => 3)
      node2 = create(:node, :lat => 5, :lon => 5)
      create(:relation_member, :relation => relation, :member => node1)
      create(:relation_member, :relation => relation, :member => node2)

      check_changeset_modify(BoundingBox.new(5, 5, 5, 5)) do |changeset_id, auth_header|
        # remove node 5 (5,5) from an existing relation
        relation_xml = xml_for_relation(relation)
        relation_xml
          .find("//osm/relation/member[@type='node'][@ref='#{node2.id}']")
          .first.remove!

        # update changeset ID to point to new changeset
        update_changeset(relation_xml, changeset_id)

        # upload the change
        put api_relation_path(relation), :params => relation_xml.to_s, :headers => auth_header
        assert_response :success, "can't update relation for remove node/bbox test"
      end
    end

    ##
    # check that relations are ordered
    def test_relation_member_ordering
      user = create(:user)
      changeset = create(:changeset, :user => user)
      node1 = create(:node)
      node2 = create(:node)
      node3 = create(:node)
      way1 = create(:way_with_nodes, :nodes_count => 2)
      way2 = create(:way_with_nodes, :nodes_count => 2)

      auth_header = bearer_authorization_header user

      doc_str = <<~OSM
        <osm>
         <relation changeset='#{changeset.id}'>
          <member ref='#{node1.id}' type='node' role='first'/>
          <member ref='#{node2.id}' type='node' role='second'/>
          <member ref='#{way1.id}' type='way' role='third'/>
          <member ref='#{way2.id}' type='way' role='fourth'/>
         </relation>
        </osm>
      OSM
      doc = XML::Parser.string(doc_str).parse

      post api_relations_path, :params => doc.to_s, :headers => auth_header
      assert_response :success, "can't create a relation: #{@response.body}"
      relation_id = @response.body.to_i

      # get it back and check the ordering
      get api_relation_path(relation_id)
      assert_response :success, "can't read back the relation: #{@response.body}"
      check_ordering(doc, @response.body)

      # insert a member at the front
      new_member = XML::Node.new "member"
      new_member["ref"] = node3.id.to_s
      new_member["type"] = "node"
      new_member["role"] = "new first"
      doc.find("//osm/relation").first.child.prev = new_member
      # update the version, should be 1?
      doc.find("//osm/relation").first["id"] = relation_id.to_s
      doc.find("//osm/relation").first["version"] = 1.to_s

      # upload the next version of the relation
      put api_relation_path(relation_id), :params => doc.to_s, :headers => auth_header
      assert_response :success, "can't update relation: #{@response.body}"
      assert_equal 2, @response.body.to_i

      # get it back again and check the ordering again
      get api_relation_path(relation_id)
      assert_response :success, "can't read back the relation: #{@response.body}"
      check_ordering(doc, @response.body)

      # check the ordering in the history tables:
      with_controller(OldRelationsController.new) do
        get api_relation_version_path(relation_id, 2)
        assert_response :success, "can't read back version 2 of the relation #{relation_id}"
        check_ordering(doc, @response.body)
      end
    end

    ##
    # check that relations can contain duplicate members
    def test_relation_member_duplicates
      private_user = create(:user, :data_public => false)
      user = create(:user)
      changeset = create(:changeset, :user => user)
      node1 = create(:node)
      node2 = create(:node)

      doc_str = <<~OSM
        <osm>
         <relation changeset='#{changeset.id}'>
          <member ref='#{node1.id}' type='node' role='forward'/>
          <member ref='#{node2.id}' type='node' role='forward'/>
          <member ref='#{node1.id}' type='node' role='forward'/>
          <member ref='#{node2.id}' type='node' role='forward'/>
         </relation>
        </osm>
      OSM
      doc = XML::Parser.string(doc_str).parse

      ## First try with the private user
      auth_header = bearer_authorization_header private_user

      post api_relations_path, :params => doc.to_s, :headers => auth_header
      assert_response :forbidden

      ## Now try with the public user
      auth_header = bearer_authorization_header user

      post api_relations_path, :params => doc.to_s, :headers => auth_header
      assert_response :success, "can't create a relation: #{@response.body}"
      relation_id = @response.body.to_i

      # get it back and check the ordering
      get api_relation_path(relation_id)
      assert_response :success, "can't read back the relation: #{relation_id}"
      check_ordering(doc, @response.body)
    end

    ##
    # test that the ordering of elements in the history is the same as in current.
    def test_history_ordering
      user = create(:user)
      changeset = create(:changeset, :user => user)
      node1 = create(:node)
      node2 = create(:node)
      node3 = create(:node)
      node4 = create(:node)

      doc_str = <<~OSM
        <osm>
         <relation changeset='#{changeset.id}'>
          <member ref='#{node1.id}' type='node' role='forward'/>
          <member ref='#{node4.id}' type='node' role='forward'/>
          <member ref='#{node3.id}' type='node' role='forward'/>
          <member ref='#{node2.id}' type='node' role='forward'/>
         </relation>
        </osm>
      OSM
      doc = XML::Parser.string(doc_str).parse
      auth_header = bearer_authorization_header user

      post api_relations_path, :params => doc.to_s, :headers => auth_header
      assert_response :success, "can't create a relation: #{@response.body}"
      relation_id = @response.body.to_i

      # check the ordering in the current tables:
      get api_relation_path(relation_id)
      assert_response :success, "can't read back the relation: #{@response.body}"
      check_ordering(doc, @response.body)

      # check the ordering in the history tables:
      with_controller(OldRelationsController.new) do
        get api_relation_version_path(relation_id, 1)
        assert_response :success, "can't read back version 1 of the relation: #{@response.body}"
        check_ordering(doc, @response.body)
      end
    end

    ##
    # remove all the members from a relation. the result is pretty useless, but
    # still technically valid.
    def test_remove_all_members
      relation = create(:relation)
      node1 = create(:node, :lat => 0.3, :lon => 0.3)
      node2 = create(:node, :lat => 0.5, :lon => 0.5)
      way = create(:way)
      create(:way_node, :way => way, :node => node1)
      create(:relation_member, :relation => relation, :member => way)
      create(:relation_member, :relation => relation, :member => node2)

      check_changeset_modify(BoundingBox.new(0.3, 0.3, 0.5, 0.5)) do |changeset_id, auth_header|
        relation_xml = xml_for_relation(relation)
        relation_xml
          .find("//osm/relation/member")
          .each(&:remove!)

        # update changeset ID to point to new changeset
        update_changeset(relation_xml, changeset_id)

        # upload the change
        put api_relation_path(relation), :params => relation_xml.to_s, :headers => auth_header
        assert_response :success, "can't update relation for remove all members test"
        checkrelation = Relation.find(relation.id)
        assert_not_nil(checkrelation,
                       "uploaded relation not found in database after upload")
        assert_equal(0, checkrelation.members.length,
                     "relation contains members but they should have all been deleted")
      end
    end

    ##
    # test initial rate limit
    def test_initial_rate_limit
      # create a user
      user = create(:user)

      # create some nodes
      node1 = create(:node)
      node2 = create(:node)

      # create a changeset that puts us near the initial rate limit
      changeset = create(:changeset, :user => user,
                                     :created_at => Time.now.utc - 5.minutes,
                                     :num_changes => Settings.initial_changes_per_hour - 1)

      # create authentication header
      auth_header = bearer_authorization_header user

      # try creating a relation
      xml = "<osm><relation changeset='#{changeset.id}'>" \
            "<member  ref='#{node1.id}' type='node' role='some'/>" \
            "<member  ref='#{node2.id}' type='node' role='some'/>" \
            "<tag k='test' v='yes' /></relation></osm>"
      post api_relations_path, :params => xml, :headers => auth_header
      assert_response :success, "relation create did not return success status"

      # get the id of the relation we created
      relationid = @response.body

      # try updating the relation, which should be rate limited
      xml = "<osm><relation id='#{relationid}' version='1' changeset='#{changeset.id}'>" \
            "<member  ref='#{node2.id}' type='node' role='some'/>" \
            "<member  ref='#{node1.id}' type='node' role='some'/>" \
            "<tag k='test' v='yes' /></relation></osm>"
      put api_relation_path(relationid), :params => xml, :headers => auth_header
      assert_response :too_many_requests, "relation update did not hit rate limit"

      # try deleting the relation, which should be rate limited
      xml = "<osm><relation id='#{relationid}' version='2' changeset='#{changeset.id}'/></osm>"
      delete api_relation_path(relationid), :params => xml, :headers => auth_header
      assert_response :too_many_requests, "relation delete did not hit rate limit"

      # try creating a relation, which should be rate limited
      xml = "<osm><relation changeset='#{changeset.id}'>" \
            "<member  ref='#{node1.id}' type='node' role='some'/>" \
            "<member  ref='#{node2.id}' type='node' role='some'/>" \
            "<tag k='test' v='yes' /></relation></osm>"
      post api_relations_path, :params => xml, :headers => auth_header
      assert_response :too_many_requests, "relation create did not hit rate limit"
    end

    ##
    # test maximum rate limit
    def test_maximum_rate_limit
      # create a user
      user = create(:user)

      # create some nodes
      node1 = create(:node)
      node2 = create(:node)

      # create a changeset to establish our initial edit time
      changeset = create(:changeset, :user => user,
                                     :created_at => Time.now.utc - 28.days)

      # create changeset to put us near the maximum rate limit
      total_changes = Settings.max_changes_per_hour - 1
      while total_changes.positive?
        changes = [total_changes, Changeset::MAX_ELEMENTS].min
        changeset = create(:changeset, :user => user,
                                       :created_at => Time.now.utc - 5.minutes,
                                       :num_changes => changes)
        total_changes -= changes
      end

      # create authentication header
      auth_header = bearer_authorization_header user

      # try creating a relation
      xml = "<osm><relation changeset='#{changeset.id}'>" \
            "<member  ref='#{node1.id}' type='node' role='some'/>" \
            "<member  ref='#{node2.id}' type='node' role='some'/>" \
            "<tag k='test' v='yes' /></relation></osm>"
      post api_relations_path, :params => xml, :headers => auth_header
      assert_response :success, "relation create did not return success status"

      # get the id of the relation we created
      relationid = @response.body

      # try updating the relation, which should be rate limited
      xml = "<osm><relation id='#{relationid}' version='1' changeset='#{changeset.id}'>" \
            "<member  ref='#{node2.id}' type='node' role='some'/>" \
            "<member  ref='#{node1.id}' type='node' role='some'/>" \
            "<tag k='test' v='yes' /></relation></osm>"
      put api_relation_path(relationid), :params => xml, :headers => auth_header
      assert_response :too_many_requests, "relation update did not hit rate limit"

      # try deleting the relation, which should be rate limited
      xml = "<osm><relation id='#{relationid}' version='2' changeset='#{changeset.id}'/></osm>"
      delete api_relation_path(relationid), :params => xml, :headers => auth_header
      assert_response :too_many_requests, "relation delete did not hit rate limit"

      # try creating a relation, which should be rate limited
      xml = "<osm><relation changeset='#{changeset.id}'>" \
            "<member  ref='#{node1.id}' type='node' role='some'/>" \
            "<member  ref='#{node2.id}' type='node' role='some'/>" \
            "<tag k='test' v='yes' /></relation></osm>"
      post api_relations_path, :params => xml, :headers => auth_header
      assert_response :too_many_requests, "relation create did not hit rate limit"
    end

    private

    ##
    # checks that the XML document and the string arguments have
    # members in the same order.
    def check_ordering(doc, xml)
      new_doc = XML::Parser.string(xml).parse

      doc_members = doc.find("//osm/relation/member").collect do |m|
        [m["ref"].to_i, m["type"].to_sym, m["role"]]
      end

      new_members = new_doc.find("//osm/relation/member").collect do |m|
        [m["ref"].to_i, m["type"].to_sym, m["role"]]
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
      auth_header = bearer_authorization_header create(:user, :data_public => false)

      # create a new changeset for this operation, so we are assured
      # that the bounding box will be newly-generated.
      with_controller(Api::ChangesetsController.new) do
        xml = "<osm><changeset/></osm>"
        post api_changesets_path, :params => xml, :headers => auth_header
        assert_response :forbidden, "shouldn't be able to create changeset for modify test, as should get forbidden"
      end

      ## Now do the whole thing with the public user
      auth_header = bearer_authorization_header

      # create a new changeset for this operation, so we are assured
      # that the bounding box will be newly-generated.
      changeset_id = with_controller(Api::ChangesetsController.new) do
        xml = "<osm><changeset/></osm>"
        post api_changesets_path, :params => xml, :headers => auth_header
        assert_response :success, "couldn't create changeset for modify test"
        @response.body.to_i
      end

      # go back to the block to do the actual modifies
      yield changeset_id, auth_header

      # now download the changeset to check its bounding box
      with_controller(Api::ChangesetsController.new) do
        get api_changeset_path(changeset_id)
        assert_response :success, "can't re-read changeset for modify test"
        assert_select "osm>changeset", 1, "Changeset element doesn't exist in #{@response.body}"
        assert_select "osm>changeset[id='#{changeset_id}']", 1, "Changeset id=#{changeset_id} doesn't exist in #{@response.body}"
        assert_select "osm>changeset[min_lon='#{format('%<lon>.7f', :lon => bbox.min_lon)}']", 1, "Changeset min_lon wrong in #{@response.body}"
        assert_select "osm>changeset[min_lat='#{format('%<lat>.7f', :lat => bbox.min_lat)}']", 1, "Changeset min_lat wrong in #{@response.body}"
        assert_select "osm>changeset[max_lon='#{format('%<lon>.7f', :lon => bbox.max_lon)}']", 1, "Changeset max_lon wrong in #{@response.body}"
        assert_select "osm>changeset[max_lat='#{format('%<lat>.7f', :lat => bbox.max_lat)}']", 1, "Changeset max_lat wrong in #{@response.body}"
      end
    end

    ##
    # yields the relation with the given +id+ (and optional +version+
    # to read from the history tables) into the block. the parsed XML
    # doc is returned.
    def with_relation(id, ver = nil)
      if ver.nil?
        get api_relation_path(id)
      else
        with_controller(OldRelationsController.new) do
          get api_relation_version_path(id, ver)
        end
      end
      assert_response :success
      yield xml_parse(@response.body)
    end

    ##
    # updates the relation (XML) +rel+ and
    # yields the new version of that relation into the block.
    # the parsed XML doc is returned.
    def with_update(rel, headers)
      rel_id = rel.find("//osm/relation").first["id"].to_i
      put api_relation_path(rel_id), :params => rel.to_s, :headers => headers
      assert_response :success, "can't update relation: #{@response.body}"
      version = @response.body.to_i

      # now get the new version
      get api_relation_path(rel_id)
      assert_response :success
      new_rel = xml_parse(@response.body)

      yield new_rel

      version
    end

    ##
    # updates the relation (XML) +rel+ via the diff-upload API and
    # yields the new version of that relation into the block.
    # the parsed XML doc is returned.
    def with_update_diff(rel, headers)
      rel_id = rel.find("//osm/relation").first["id"].to_i
      cs_id = rel.find("//osm/relation").first["changeset"].to_i
      version = nil

      with_controller(Api::ChangesetsController.new) do
        doc = OSM::API.new.xml_doc
        change = XML::Node.new "osmChange"
        doc.root = change
        modify = XML::Node.new "modify"
        change << modify
        modify << doc.import(rel.find("//osm/relation").first)

        post changeset_upload_path(cs_id), :params => doc.to_s, :headers => headers
        assert_response :success, "can't upload diff relation: #{@response.body}"
        version = xml_parse(@response.body).find("//diffResult/relation").first["new_version"].to_i
      end

      # now get the new version
      get api_relation_path(rel_id)
      assert_response :success
      new_rel = xml_parse(@response.body)

      yield new_rel

      version
    end

    ##
    # returns a k->v hash of tags from an xml doc
    def get_tags_as_hash(a)
      a.find("//osm/relation/tag").sort_by { |v| v["k"] }.each_with_object({}) do |v, h|
        h[v["k"]] = v["v"]
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
                     "Tags which were not altered should be the same. " \
                     "#{a_tags.inspect} != #{b_tags.inspect}"
      end
    end

    ##
    # update the changeset_id of a node element
    def update_changeset(xml, changeset_id)
      xml_attr_rewrite(xml, "changeset", changeset_id)
    end

    ##
    # update an attribute in the node element
    def xml_attr_rewrite(xml, name, value)
      xml.find("//osm/relation").first[name] = value.to_s
      xml
    end

    ##
    # parse some xml
    def xml_parse(xml)
      parser = XML::Parser.string(xml)
      parser.parse
    end
  end
end
