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

      get api_relation_path(relation)
      assert_response :success
      rel = xml_parse(@response.body)
      rel_id = rel.find("//osm/relation").first["id"].to_i

      # alter one of the tags
      tag = rel.find("//osm/relation/tag").first
      tag["v"] = "some changed value"
      update_changeset(rel, changeset.id)
      put api_relation_path(rel_id), :params => rel.to_s, :headers => auth_header
      assert_response :success, "can't update relation: #{@response.body}"
      new_version = @response.body.to_i

      # check that the downloaded tags are the same as the uploaded tags...
      get api_relation_path(rel_id)
      assert_tags_equal_response rel

      # check the original one in the current_* table again
      get api_relation_path(relation)
      assert_tags_equal_response rel

      # now check the version in the history
      get api_relation_version_path(relation, new_version)
      assert_tags_equal_response rel
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

      get api_relation_path(relation)
      assert_response :success
      rel = xml_parse(@response.body)
      rel_id = rel.find("//osm/relation").first["id"].to_i

      # alter one of the tags
      tag = rel.find("//osm/relation/tag").first
      tag["v"] = "some changed value"
      update_changeset(rel, changeset.id)
      new_version = nil
      with_controller(Api::ChangesetsController.new) do
        doc = OSM::API.new.xml_doc
        change = XML::Node.new "osmChange"
        doc.root = change
        modify = XML::Node.new "modify"
        change << modify
        modify << doc.import(rel.find("//osm/relation").first)

        post api_changeset_upload_path(changeset), :params => doc.to_s, :headers => auth_header
        assert_response :success, "can't upload diff relation: #{@response.body}"
        new_version = xml_parse(@response.body).find("//diffResult/relation").first["new_version"].to_i
      end

      # check that the downloaded tags are the same as the uploaded tags...
      get api_relation_path(rel_id)
      assert_tags_equal_response rel

      # check the original one in the current_* table again
      get api_relation_path(relation)
      assert_tags_equal_response rel

      # now check the version in the history
      get api_relation_version_path(relation, new_version)
      assert_tags_equal_response rel
    end

    def test_update_wrong_id
      user = create(:user)
      changeset = create(:changeset, :user => user)
      relation = create(:relation)
      other_relation = create(:relation)

      auth_header = bearer_authorization_header user
      get api_relation_path(relation)
      assert_response :success
      rel = xml_parse(@response.body)

      update_changeset(rel, changeset.id)
      put api_relation_path(other_relation), :params => rel.to_s, :headers => auth_header
      assert_response :bad_request
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
    # returns a k->v hash of tags from an xml doc
    def get_tags_as_hash(a)
      a.find("//osm/relation/tag").to_h do |tag|
        [tag["k"], tag["v"]]
      end
    end

    ##
    # assert that tags on relation document +rel+
    # are equal to tags in response
    def assert_tags_equal_response(rel)
      assert_response :success
      response_xml = xml_parse(@response.body)

      # turn the XML doc into tags hashes
      rel_tags = get_tags_as_hash(rel)
      response_tags = get_tags_as_hash(response_xml)

      assert_equal rel_tags, response_tags, "Tags should be identical."
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
