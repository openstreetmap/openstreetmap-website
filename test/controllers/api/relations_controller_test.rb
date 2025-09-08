# frozen_string_literal: true

require "test_helper"
require_relative "elements_test_helper"

module Api
  class RelationsControllerTest < ActionDispatch::IntegrationTest
    include ElementsTestHelper

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
      assert_equal(4, js["elements"].count { |a| a["type"] == "relation" })
      assert_equal(1, js["elements"].count { |a| a["id"] == relation1.id && a["visible"].nil? })
      assert_equal(1, js["elements"].count { |a| a["id"] == relation2.id && a["visible"] == false })
      assert_equal(1, js["elements"].count { |a| a["id"] == relation3.id && a["visible"].nil? })
      assert_equal(1, js["elements"].count { |a| a["id"] == relation4.id && a["visible"].nil? })

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
    # Test creating relations.
    # -------------------------------------

    def test_create_without_members_by_private_user
      with_unchanging_request([:data_public => false]) do |headers, changeset|
        osm = <<~OSM
          <osm>
            <relation changeset='#{changeset.id}'>
              <tag k='test' v='yes' />
            </relation>
          </osm>
        OSM

        post api_relations_path, :params => osm, :headers => headers

        assert_response :forbidden, "relation upload should have failed with forbidden"
      end
    end

    def test_create_with_node_member_with_role_by_private_user
      node = create(:node)

      with_unchanging_request([:data_public => false]) do |headers, changeset|
        osm = <<~OSM
          <osm>
            <relation changeset='#{changeset.id}'>
              <member ref='#{node.id}' type='node' role='some'/>
              <tag k='test' v='yes' />
            </relation>
          </osm>
        OSM

        post api_relations_path, :params => osm, :headers => headers

        assert_response :forbidden, "relation upload did not return forbidden status"
      end
    end

    def test_create_with_node_member_without_role_by_private_user
      node = create(:node)

      with_unchanging_request([:data_public => false]) do |headers, changeset|
        osm = <<~OSM
          <osm>
            <relation changeset='#{changeset.id}'>
              <member ref='#{node.id}' type='node'/>
              <tag k='test' v='yes' />
            </relation>
          </osm>
        OSM

        post api_relations_path, :params => osm, :headers => headers

        assert_response :forbidden, "relation upload did not return forbidden status"
      end
    end

    def test_create_with_node_and_way_members_by_private_user
      node = create(:node)
      way = create(:way_with_nodes, :nodes_count => 2)

      with_unchanging_request([:data_public => false]) do |headers, changeset|
        osm = <<~OSM
          <osm>
            <relation changeset='#{changeset.id}'>
              <member type='node' ref='#{node.id}' role='some'/>
              <member type='way' ref='#{way.id}' role='other'/>
              <tag k='test' v='yes' />
            </relation>
          </osm>
        OSM

        post api_relations_path, :params => osm, :headers => headers

        assert_response :forbidden, "relation upload did not return success status"
      end
    end

    def test_create_without_members
      with_request do |headers, changeset|
        assert_difference "Relation.count" => 1,
                          "RelationMember.count" => 0 do
          osm = <<~OSM
            <osm>
              <relation changeset='#{changeset.id}'>
                <tag k='test' v='yes' />
              </relation>
            </osm>
          OSM

          post api_relations_path, :params => osm, :headers => headers

          assert_response :success, "relation upload did not return success status"
        end

        created_relation_id = @response.body
        relation = Relation.find(created_relation_id)
        assert_empty relation.members
        assert_equal({ "test" => "yes" }, relation.tags)
        assert_equal changeset.id, relation.changeset_id, "saved relation does not belong in the changeset it was assigned to"
        assert relation.visible, "saved relation is not visible"

        changeset.reload
        assert_equal 1, changeset.num_changes
        assert_predicate changeset, :num_type_changes_in_sync?
        assert_equal 1, changeset.num_created_relations
      end
    end

    def test_create_with_node_member_with_role
      node = create(:node)

      with_request do |headers, changeset|
        assert_difference "Relation.count" => 1,
                          "RelationMember.count" => 1 do
          osm = <<~OSM
            <osm>
              <relation changeset='#{changeset.id}'>
                <member ref='#{node.id}' type='node' role='some'/>
                <tag k='test' v='yes' />
              </relation>
            </osm>
          OSM

          post api_relations_path, :params => osm, :headers => headers

          assert_response :success, "relation upload did not return success status"
        end

        created_relation_id = @response.body
        relation = Relation.find(created_relation_id)
        assert_equal [["Node", node.id, "some"]], relation.members
        assert_equal({ "test" => "yes" }, relation.tags)
        assert_equal changeset.id, relation.changeset_id, "saved relation does not belong in the changeset it was assigned to"
        assert relation.visible, "saved relation is not visible"

        changeset.reload
        assert_equal 1, changeset.num_changes
        assert_predicate changeset, :num_type_changes_in_sync?
        assert_equal 1, changeset.num_created_relations
      end
    end

    def test_create_with_node_member_without_role
      node = create(:node)

      with_request do |headers, changeset|
        assert_difference "Relation.count" => 1,
                          "RelationMember.count" => 1 do
          osm = <<~OSM
            <osm>
              <relation changeset='#{changeset.id}'>
                <member ref='#{node.id}' type='node'/>
                <tag k='test' v='yes' />
              </relation>
            </osm>
          OSM

          post api_relations_path, :params => osm, :headers => headers

          assert_response :success, "relation upload did not return success status"
        end

        created_relation_id = @response.body
        relation = Relation.find(created_relation_id)
        assert_equal [["Node", node.id, ""]], relation.members
        assert_equal({ "test" => "yes" }, relation.tags)
        assert_equal changeset.id, relation.changeset_id, "saved relation does not belong in the changeset it was assigned to"
        assert relation.visible, "saved relation is not visible"

        changeset.reload
        assert_equal 1, changeset.num_changes
        assert_predicate changeset, :num_type_changes_in_sync?
        assert_equal 1, changeset.num_created_relations
      end
    end

    def test_create_with_node_and_way_members
      node = create(:node)
      way = create(:way_with_nodes, :nodes_count => 2)

      with_request do |headers, changeset|
        assert_difference "Relation.count" => 1,
                          "RelationMember.count" => 2 do
          osm = <<~OSM
            <osm>
              <relation changeset='#{changeset.id}'>
                <member type='node' ref='#{node.id}' role='some'/>
                <member type='way' ref='#{way.id}' role='other'/>
                <tag k='test' v='yes' />
              </relation>
            </osm>
          OSM

          post api_relations_path, :params => osm, :headers => headers

          assert_response :success, "relation upload did not return success status"
        end

        created_relation_id = @response.body
        relation = Relation.find(created_relation_id)
        assert_equal [["Node", node.id, "some"],
                      ["Way", way.id, "other"]], relation.members
        assert_equal({ "test" => "yes" }, relation.tags)
        assert_equal changeset.id, relation.changeset_id, "saved relation does not belong in the changeset it was assigned to"
        assert relation.visible, "saved relation is not visible"

        changeset.reload
        assert_equal 1, changeset.num_changes
        assert_predicate changeset, :num_type_changes_in_sync?
        assert_equal 1, changeset.num_created_relations
      end
    end

    def test_create_in_missing_changeset
      node = create(:node)

      with_unchanging_request do |headers|
        osm = <<~OSM
          <osm>
            <relation changeset='0'>
              <member type='node' ref='#{node.id}' role='some'/>
            </relation>
          </osm>
        OSM

        post api_relations_path, :params => osm, :headers => headers

        assert_response :conflict
      end
    end

    def test_create_with_missing_node_member
      with_unchanging_request do |headers, changeset|
        osm = <<~OSM
          <osm>
            <relation changeset='#{changeset.id}'>
              <member type='node' ref='0'/>
            </relation>
          </osm>
        OSM

        post api_relations_path, :params => osm, :headers => headers

        assert_response :precondition_failed, "relation upload with invalid node did not return 'precondition failed'"
        assert_equal "Precondition failed: Relation with id  cannot be saved due to Node with id 0", @response.body
      end
    end

    def test_create_with_invalid_member_type
      node = create(:node)

      with_unchanging_request do |headers, changeset|
        osm = <<~OSM
          <osm>
            <relation changeset='#{changeset.id}'>
              <member type='type' ref='#{node.id}' role=''/>
            </relation>
          </osm>
        OSM

        post api_relations_path, :params => osm, :headers => headers

        assert_response :bad_request
        assert_match(/Cannot parse valid relation from xml string/, @response.body)
        assert_match(/The type is not allowed only, /, @response.body)
      end
    end

    def test_create_and_show
      user = create(:user)
      changeset = create(:changeset, :user => user)

      osm = <<~OSM
        <osm>
          <relation changeset='#{changeset.id}'/>
        </osm>
      OSM

      post api_relations_path, :params => osm, :headers => bearer_authorization_header(user)

      assert_response :success, "relation upload did not return success status"

      created_relation_id = @response.body

      get api_relation_path(created_relation_id)

      assert_response :success
    end

    def test_create_race_condition
      user = create(:user)
      changeset = create(:changeset, :user => user)
      node = create(:node)
      auth_header = bearer_authorization_header user
      path = api_relations_path
      concurrency_level = 16

      threads = Array.new(concurrency_level) do
        Thread.new do
          osm = <<~OSM
            <osm>
              <relation changeset='#{changeset.id}'>
                <member type='node' ref='#{node.id}' role=''/>
              </relation>
            </osm>
          OSM
          post path, :params => osm, :headers => auth_header
        end
      end
      threads.each(&:join)

      changeset.reload
      assert_equal concurrency_level, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
      assert_equal concurrency_level, changeset.num_created_relations
    end

    # ------------------------------------
    # Test updating relations
    # ------------------------------------

    def test_update
      relation = create(:relation)

      with_request do |headers, changeset|
        osm_xml = xml_for_relation relation
        osm_xml = update_changeset osm_xml, changeset.id

        put api_relation_path(relation), :params => osm_xml.to_s, :headers => headers

        assert_response :success

        relation.reload
        assert_equal 2, relation.version

        changeset.reload
        assert_equal 1, changeset.num_changes
        assert_predicate changeset, :num_type_changes_in_sync?
        assert_equal 1, changeset.num_modified_relations
      end
    end

    def test_update_in_missing_changeset
      with_unchanging(:relation) do |relation|
        with_unchanging_request do |headers|
          osm_xml = xml_for_relation relation
          osm_xml = update_changeset osm_xml, 0

          put api_relation_path(relation), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict, "update with changeset=0 should be rejected"
        end
      end
    end

    def test_update_other_relation
      with_unchanging(:relation) do |relation|
        with_unchanging(:relation) do |other_relation|
          with_unchanging_request do |headers, changeset|
            osm_xml = xml_for_relation other_relation
            osm_xml = update_changeset osm_xml, changeset.id

            put api_relation_path(relation), :params => osm_xml.to_s, :headers => headers

            assert_response :bad_request
          end
        end
      end
    end

    # -------------------------------------
    # Test deleting relations.
    # -------------------------------------

    def test_destroy_when_unauthorized
      with_unchanging(:relation) do |relation|
        delete api_relation_path(relation)

        assert_response :unauthorized
      end
    end

    def test_destroy_without_payload_by_private_user
      with_unchanging(:relation) do |relation|
        with_unchanging_request([:data_public => false]) do |headers|
          delete api_relation_path(relation), :headers => headers

          assert_response :forbidden
        end
      end
    end

    def test_destroy_without_changeset_id_by_private_user
      with_unchanging(:relation) do |relation|
        with_unchanging_request([:data_public => false]) do |headers|
          osm = "<osm><relation id='#{relation.id}' version='#{relation.version}'/></osm>"

          delete api_relation_path(relation), :params => osm, :headers => headers

          assert_response :forbidden
        end
      end
    end

    def test_destroy_in_closed_changeset_by_private_user
      with_unchanging(:relation) do |relation|
        with_unchanging_request([:data_public => false], [:closed]) do |headers, changeset|
          osm_xml = xml_for_relation relation
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_relation_path(relation), :params => osm_xml.to_s, :headers => headers

          assert_response :forbidden
        end
      end
    end

    def test_destroy_in_missing_changeset_by_private_user
      with_unchanging(:relation) do |relation|
        with_unchanging_request([:data_public => false]) do |headers|
          osm_xml = xml_for_relation relation
          osm_xml = update_changeset osm_xml, 0

          delete api_relation_path(relation), :params => osm_xml.to_s, :headers => headers

          assert_response :forbidden
        end
      end
    end

    def test_destroy_relation_used_by_other_relation_by_private_user
      with_unchanging(:relation) do |relation|
        create(:relation_member, :member => relation)

        with_unchanging_request([:data_public => false]) do |headers, changeset|
          osm_xml = xml_for_relation relation
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_relation_path(relation), :params => osm_xml.to_s, :headers => headers

          assert_response :forbidden
        end
      end
    end

    def test_destroy_by_private_user
      with_unchanging(:relation) do |relation|
        with_unchanging_request([:data_public => false]) do |headers, changeset|
          osm_xml = xml_for_relation relation
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_relation_path(relation), :params => osm_xml.to_s, :headers => headers

          assert_response :forbidden
        end
      end
    end

    def test_destroy_deleted_relation_by_private_user
      with_unchanging(:relation, :deleted) do |relation|
        with_unchanging_request([:data_public => false]) do |headers, changeset|
          osm_xml = xml_for_relation relation
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_relation_path(relation), :params => osm_xml.to_s, :headers => headers

          assert_response :forbidden
        end
      end
    end

    def test_destroy_missing_relation_by_private_user
      with_unchanging_request([:data_public => false]) do |headers|
        delete api_relation_path(0), :headers => headers

        assert_response :forbidden
      end
    end

    def test_destroy_without_payload
      with_unchanging(:relation) do |relation|
        with_unchanging_request do |headers|
          delete api_relation_path(relation), :headers => headers

          assert_response :bad_request
        end
      end
    end

    def test_destroy_without_changeset_id
      with_unchanging(:relation) do |relation|
        with_unchanging_request do |headers|
          osm = "<osm><relation id='#{relation.id}' version='#{relation.version}'/></osm>"

          delete api_relation_path(relation), :params => osm, :headers => headers

          assert_response :bad_request
          assert_match(/Changeset id is missing/, @response.body)
        end
      end
    end

    def test_destroy_in_closed_changeset
      with_unchanging(:relation) do |relation|
        with_unchanging_request([], [:closed]) do |headers, changeset|
          osm_xml = xml_for_relation relation
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_relation_path(relation), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict
        end
      end
    end

    def test_destroy_in_missing_changeset
      with_unchanging(:relation) do |relation|
        with_unchanging_request do |headers|
          osm_xml = xml_for_relation relation
          osm_xml = update_changeset osm_xml, 0

          delete api_relation_path(relation), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict
        end
      end
    end

    def test_destroy_in_changeset_of_other_user
      with_unchanging(:relation) do |relation|
        other_user = create(:user)

        with_unchanging_request([], [:user => other_user]) do |headers, changeset|
          osm_xml = xml_for_relation relation
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_relation_path(relation), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict, "shouldn't be able to delete a relation in a changeset owned by someone else (#{@response.body})"
        end
      end
    end

    def test_destroy_other_relation
      with_unchanging(:relation) do |relation|
        with_unchanging(:relation) do |other_relation|
          with_unchanging_request do |headers, changeset|
            osm_xml = xml_for_relation other_relation
            osm_xml = update_changeset osm_xml, changeset.id

            delete api_relation_path(relation), :params => osm_xml.to_s, :headers => headers

            assert_response :bad_request, "shouldn't be able to delete a relation when payload is different to the url"
          end
        end
      end
    end

    def test_destroy_relation_used_by_other_relation
      with_unchanging(:relation) do |relation|
        super_relation = create(:relation)
        create(:relation_member, :relation => super_relation, :member => relation)

        with_unchanging_request do |headers, changeset|
          osm_xml = xml_for_relation relation
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_relation_path(relation), :params => osm_xml.to_s, :headers => headers

          assert_response :precondition_failed, "shouldn't be able to delete a relation used in a relation (#{@response.body})"
          assert_equal "Precondition failed: The relation #{relation.id} is used in relation #{super_relation.id}.", @response.body
        end
      end
    end

    def test_destroy
      relation = create(:relation)
      create_list(:relation_tag, 4, :relation => relation)

      with_request do |headers, changeset|
        osm_xml = xml_for_relation relation
        osm_xml = update_changeset osm_xml, changeset.id

        delete api_relation_path(relation), :params => osm_xml.to_s, :headers => headers

        assert_response :success
        assert_operator @response.body.to_i, :>, relation.version, "delete request should return a new version number for relation"

        changeset.reload
        assert_equal 1, changeset.num_changes
        assert_predicate changeset, :num_type_changes_in_sync?
        assert_equal 1, changeset.num_deleted_relations
      end
    end

    def test_destroy_deleted_relation
      with_unchanging(:relation, :deleted) do |relation|
        with_unchanging_request do |headers, changeset|
          osm_xml = xml_for_relation relation
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_relation_path(relation), :params => osm_xml.to_s, :headers => headers

          assert_response :gone
        end
      end
    end

    def test_destroy_super_relation_then_used_relation
      used_relation = create(:relation)
      super_relation = create(:relation)
      create(:relation_member, :relation => super_relation, :member => used_relation)

      with_request do |headers, changeset|
        osm_xml = xml_for_relation super_relation
        osm_xml = update_changeset osm_xml, changeset.id

        delete api_relation_path(super_relation), :params => osm_xml.to_s, :headers => headers

        assert_response :success
      end

      with_request do |headers, changeset|
        osm_xml = xml_for_relation used_relation
        osm_xml = update_changeset osm_xml, changeset.id

        delete api_relation_path(used_relation), :params => osm_xml.to_s, :headers => headers

        assert_response :success, "should be able to delete a relation used in an old relation (#{@response.body})"
      end
    end

    def test_destroy_missing_relation
      with_unchanging_request do |headers|
        delete api_relation_path(0), :headers => headers

        assert_response :not_found
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
      xml = <<~OSM
        <osm>
          <relation changeset='#{changeset.id}'>
            <member ref='#{node1.id}' type='node' role='some'/>
            <member ref='#{node2.id}' type='node' role='some'/>
          </relation>
        </osm>
      OSM
      post api_relations_path, :params => xml, :headers => auth_header
      assert_response :success, "relation create did not return success status"

      # get the id of the relation we created
      relationid = @response.body

      # try updating the relation, which should be rate limited
      xml = <<~OSM
        <osm>
          <relation id='#{relationid}' version='1' changeset='#{changeset.id}'>
            <member ref='#{node2.id}' type='node' role='some'/>
            <member ref='#{node1.id}' type='node' role='some'/>
          </relation>
        </osm>
      OSM
      put api_relation_path(relationid), :params => xml, :headers => auth_header
      assert_response :too_many_requests, "relation update did not hit rate limit"

      # try deleting the relation, which should be rate limited
      xml = "<osm><relation id='#{relationid}' version='2' changeset='#{changeset.id}'/></osm>"
      delete api_relation_path(relationid), :params => xml, :headers => auth_header
      assert_response :too_many_requests, "relation delete did not hit rate limit"

      # try creating a relation, which should be rate limited
      xml = <<~OSM
        <osm>
          <relation changeset='#{changeset.id}'>
            <member ref='#{node1.id}' type='node' role='some'/>
            <member ref='#{node2.id}' type='node' role='some'/>
          </relation>
        </osm>
      OSM
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
      xml = <<~OSM
        <osm>
          <relation changeset='#{changeset.id}'>
            <member ref='#{node1.id}' type='node' role='some'/>
            <member ref='#{node2.id}' type='node' role='some'/>
          </relation>
        </osm>
      OSM
      post api_relations_path, :params => xml, :headers => auth_header
      assert_response :success, "relation create did not return success status"

      # get the id of the relation we created
      relationid = @response.body

      # try updating the relation, which should be rate limited
      xml = <<~OSM
        <osm>
          <relation id='#{relationid}' version='1' changeset='#{changeset.id}'>
            <member ref='#{node2.id}' type='node' role='some'/>
            <member ref='#{node1.id}' type='node' role='some'/>
          </relation>
        </osm>
      OSM
      put api_relation_path(relationid), :params => xml, :headers => auth_header
      assert_response :too_many_requests, "relation update did not hit rate limit"

      # try deleting the relation, which should be rate limited
      xml = "<osm><relation id='#{relationid}' version='2' changeset='#{changeset.id}'/></osm>"
      delete api_relation_path(relationid), :params => xml, :headers => auth_header
      assert_response :too_many_requests, "relation delete did not hit rate limit"

      # try creating a relation, which should be rate limited
      xml = <<~OSM
        <osm>
          <relation changeset='#{changeset.id}'>
            <member ref='#{node1.id}' type='node' role='some'/>
            <member ref='#{node2.id}' type='node' role='some'/>
          </relation>
        </osm>
      OSM
      post api_relations_path, :params => xml, :headers => auth_header
      assert_response :too_many_requests, "relation create did not hit rate limit"
    end

    private

    def affected_models
      [Relation, RelationTag, RelationMember,
       OldRelation, OldRelationTag, OldRelationMember]
    end

    ##
    # update an attribute in the node element
    def xml_attr_rewrite(xml, name, value)
      xml.find("//osm/relation").first[name] = value.to_s
      xml
    end
  end
end
