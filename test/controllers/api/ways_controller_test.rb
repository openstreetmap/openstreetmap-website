# frozen_string_literal: true

require "test_helper"
require_relative "elements_test_helper"

module Api
  class WaysControllerTest < ActionDispatch::IntegrationTest
    include ElementsTestHelper

    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/ways", :method => :get },
        { :controller => "api/ways", :action => "index" }
      )
      assert_routing(
        { :path => "/api/0.6/ways.json", :method => :get },
        { :controller => "api/ways", :action => "index", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/ways", :method => :post },
        { :controller => "api/ways", :action => "create" }
      )
      assert_routing(
        { :path => "/api/0.6/way/1", :method => :get },
        { :controller => "api/ways", :action => "show", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/way/1.json", :method => :get },
        { :controller => "api/ways", :action => "show", :id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/way/1/full", :method => :get },
        { :controller => "api/ways", :action => "show", :full => true, :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/way/1/full.json", :method => :get },
        { :controller => "api/ways", :action => "show", :full => true, :id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/way/1", :method => :put },
        { :controller => "api/ways", :action => "update", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/way/1", :method => :delete },
        { :controller => "api/ways", :action => "destroy", :id => "1" }
      )

      assert_recognizes(
        { :controller => "api/ways", :action => "create" },
        { :path => "/api/0.6/way/create", :method => :put }
      )
    end

    ##
    # test fetching multiple ways
    def test_index
      way1 = create(:way)
      way2 = create(:way, :deleted)
      way3 = create(:way)
      way4 = create(:way)

      # check error when no parameter provided
      get api_ways_path
      assert_response :bad_request

      # check error when no parameter value provided
      get api_ways_path(:ways => "")
      assert_response :bad_request

      # test a working call
      get api_ways_path(:ways => "#{way1.id},#{way2.id},#{way3.id},#{way4.id}")
      assert_response :success
      assert_select "osm" do
        assert_select "way", :count => 4
        assert_select "way[id='#{way1.id}'][visible='true']", :count => 1
        assert_select "way[id='#{way2.id}'][visible='false']", :count => 1
        assert_select "way[id='#{way3.id}'][visible='true']", :count => 1
        assert_select "way[id='#{way4.id}'][visible='true']", :count => 1
      end

      # test a working call with json format
      get api_ways_path(:ways => "#{way1.id},#{way2.id},#{way3.id},#{way4.id}", :format => "json")

      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 4, js["elements"].count
      assert_equal(4, js["elements"].count { |a| a["type"] == "way" })
      assert_equal(1, js["elements"].count { |a| a["id"] == way1.id && a["visible"].nil? })
      assert_equal(1, js["elements"].count { |a| a["id"] == way2.id && a["visible"] == false })
      assert_equal(1, js["elements"].count { |a| a["id"] == way3.id && a["visible"].nil? })
      assert_equal(1, js["elements"].count { |a| a["id"] == way4.id && a["visible"].nil? })

      # check error when a non-existent way is included
      get api_ways_path(:ways => "#{way1.id},#{way2.id},#{way3.id},#{way4.id},0")
      assert_response :not_found
    end

    # -------------------------------------
    # Test showing ways.
    # -------------------------------------

    def test_show_not_found
      get api_way_path(0)
      assert_response :not_found
    end

    def test_show_deleted
      get api_way_path(create(:way, :deleted))
      assert_response :gone
    end

    def test_show
      way = create(:way, :timestamp => "2021-02-03T00:00:00Z")
      node = create(:node, :timestamp => "2021-04-05T00:00:00Z")
      create(:way_node, :way => way, :node => node)

      get api_way_path(way)

      assert_response :success
      assert_not_nil @response.header["Last-Modified"]
      assert_equal "2021-02-03T00:00:00Z", Time.parse(@response.header["Last-Modified"]).utc.xmlschema
    end

    def test_show_json
      way = create(:way_with_nodes, :nodes_count => 3)

      get api_way_path(way, :format => "json")

      assert_response :success

      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 1, js["elements"].count
      js_ways = js["elements"].filter { |e| e["type"] == "way" }
      assert_equal 1, js_ways.count
      assert_equal way.id, js_ways[0]["id"]
      assert_equal 1, js_ways[0]["version"]
    end

    ##
    # check the "full" mode
    def test_show_full
      way = create(:way_with_nodes, :nodes_count => 3)

      get api_way_path(way, :full => true)

      assert_response :success

      # Check the way is correctly returned
      assert_select "osm way[id='#{way.id}'][version='1'][visible='true']", 1

      # check that each node in the way appears once in the output as a
      # reference and as the node element.
      way.nodes.each do |n|
        assert_select "osm way nd[ref='#{n.id}']", 1
        assert_select "osm node[id='#{n.id}'][version='1'][lat='#{format('%<lat>.7f', :lat => n.lat)}'][lon='#{format('%<lon>.7f', :lon => n.lon)}']", 1
      end
    end

    def test_show_full_json
      way = create(:way_with_nodes, :nodes_count => 3)

      get api_way_path(way, :full => true, :format => "json")

      assert_response :success

      # Check the way is correctly returned
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 4, js["elements"].count
      js_ways = js["elements"].filter { |e| e["type"] == "way" }
      assert_equal 1, js_ways.count
      assert_equal way.id, js_ways[0]["id"]
      assert_equal 1, js_ways[0]["version"]

      # check that each node in the way appears once in the output as a
      # reference and as the node element.
      js_nodes = js["elements"].filter { |e| e["type"] == "node" }
      assert_equal 3, js_nodes.count

      way.nodes.each_with_index do |n, i|
        assert_equal n.id, js_ways[0]["nodes"][i]
        js_nodes_with_id = js_nodes.filter { |e| e["id"] == n.id }
        assert_equal 1, js_nodes_with_id.count
        assert_equal n.id, js_nodes_with_id[0]["id"]
        assert_equal 1, js_nodes_with_id[0]["version"]
        assert_equal n.lat, js_nodes_with_id[0]["lat"]
        assert_equal n.lon, js_nodes_with_id[0]["lon"]
      end
    end

    def test_show_full_deleted
      way = create(:way, :deleted)

      get api_way_path(way, :full => true)

      assert_response :gone
    end

    # -------------------------------------
    # Test creating ways.
    # -------------------------------------

    def test_create_by_private_user
      node1 = create(:node)
      node2 = create(:node)

      with_unchanging_request([:data_public => false]) do |headers, changeset|
        osm = <<~OSM
          <osm>
            <way changeset='#{changeset.id}'>
              <nd ref='#{node1.id}'/>
              <nd ref='#{node2.id}'/>
              <tag k='test' v='yes' />
            </way>
          </osm>
        OSM

        post api_ways_path, :params => osm, :headers => headers

        assert_response :forbidden, "way upload did not return forbidden status"
      end
    end

    def test_create
      node1 = create(:node)
      node2 = create(:node)

      with_request do |headers, changeset|
        assert_difference "Way.count" => 1,
                          "WayNode.count" => 2 do
          osm = <<~OSM
            <osm>
              <way changeset='#{changeset.id}'>
                <nd ref='#{node1.id}'/>
                <nd ref='#{node2.id}'/>
                <tag k='test' v='yes' />
              </way>
            </osm>
          OSM

          post api_ways_path, :params => osm, :headers => headers

          assert_response :success, "way upload did not return success status"
        end

        created_way_id = @response.body
        way = Way.find(created_way_id)
        assert_equal [node1, node2], way.nodes
        assert_equal changeset.id, way.changeset_id, "saved way does not belong to the correct changeset"
        assert way.visible, "saved way is not visible"

        changeset.reload
        assert_equal 1, changeset.num_changes
        assert_predicate changeset, :num_type_changes_in_sync?
        assert_equal 1, changeset.num_created_ways
      end
    end

    def test_create_in_missing_changeset
      node1 = create(:node)
      node2 = create(:node)

      with_unchanging_request do |headers|
        osm = <<~OSM
          <osm>
            <way changeset='0'>
              <nd ref='#{node1.id}'/>
              <nd ref='#{node2.id}'/>
            </way>
          </osm>
        OSM

        post api_ways_path, :params => osm, :headers => headers

        assert_response :conflict
      end
    end

    def test_create_with_missing_node_by_private_user
      with_unchanging_request([:data_public => false]) do |headers, changeset|
        osm = <<~OSM
          <osm>
            <way changeset='#{changeset.id}'>
              <nd ref='0'/>
            </way>
          </osm>
        OSM

        post api_ways_path, :params => osm, :headers => headers

        assert_response :forbidden, "way upload with invalid node using a private user did not return 'forbidden'"
      end
    end

    def test_create_without_nodes_by_private_user
      with_unchanging_request([:data_public => false]) do |headers, changeset|
        osm = <<~OSM
          <osm>
            <way changeset='#{changeset.id}' />
          </osm>
        OSM

        post api_ways_path, :params => osm, :headers => headers

        assert_response :forbidden, "way upload with no node using a private user did not return 'forbidden'"
      end
    end

    def test_create_in_closed_changeset_by_private_user
      node = create(:node)

      with_unchanging_request([:data_public => false]) do |headers, changeset|
        osm = <<~OSM
          <osm>
            <way changeset='#{changeset.id}'>
              <nd ref='#{node.id}'/>
            </way>
          </osm>
        OSM

        post api_ways_path, :params => osm, :headers => headers

        assert_response :forbidden, "way upload to closed changeset with a private user did not return 'forbidden'"
      end
    end

    def test_create_with_missing_node
      with_unchanging_request do |headers, changeset|
        osm = <<~OSM
          <osm>
            <way changeset='#{changeset.id}'>
              <nd ref='0'/>
            </way>
          </osm>
        OSM

        post api_ways_path, :params => osm, :headers => headers

        assert_response :precondition_failed, "way upload with invalid node did not return 'precondition failed'"
        assert_equal "Precondition failed: Way  requires the nodes with id in (0), which either do not exist, or are not visible.", @response.body
      end
    end

    def test_create_without_nodes
      with_unchanging_request do |headers, changeset|
        osm = <<~OSM
          <osm>
            <way changeset='#{changeset.id}' />
          </osm>
        OSM

        post api_ways_path, :params => osm, :headers => headers

        assert_response :precondition_failed, "way upload with no node did not return 'precondition failed'"
        assert_equal "Precondition failed: Cannot create way: data is invalid.", @response.body
      end
    end

    def test_create_in_closed_changeset
      node = create(:node)

      with_unchanging_request([], [:closed]) do |headers, changeset|
        osm = <<~OSM
          <osm>
            <way changeset='#{changeset.id}'>
              <nd ref='#{node.id}'/>
            </way>
          </osm>
        OSM

        post api_ways_path, :params => osm, :headers => headers

        assert_response :conflict, "way upload to closed changeset did not return 'conflict'"
      end
    end

    def test_create_with_tag_too_long
      node = create(:node)

      with_unchanging_request do |headers, changeset|
        osm = <<~OSM
          <osm>
            <way changeset='#{changeset.id}'>
              <nd ref='#{node.id}'/>
              <tag k='foo' v='#{'x' * 256}'/>
            </way>
          </osm>
        OSM

        post api_ways_path, :params => osm, :headers => headers

        assert_response :bad_request, "way upload to with too long tag did not return 'bad_request'"
      end
    end

    def test_create_with_duplicate_tags_by_private_user
      node = create(:node)

      with_unchanging_request([:data_public => false]) do |headers, changeset|
        osm = <<~OSM
          <osm>
            <way changeset='#{changeset.id}'>
              <nd ref='#{node.id}'/>
              <tag k='addr:housenumber' v='1'/>
              <tag k='addr:housenumber' v='2'/>
            </way>
          </osm>
        OSM

        post api_ways_path, :params => osm, :headers => headers

        assert_response :forbidden, "adding new duplicate tags to a way with a non-public user should fail with 'forbidden'"
      end
    end

    def test_create_with_duplicate_tags
      node = create(:node)

      with_unchanging_request do |headers, changeset|
        osm = <<~OSM
          <osm>
            <way changeset='#{changeset.id}'>
              <nd ref='#{node.id}'/>
              <tag k='addr:housenumber' v='1'/>
              <tag k='addr:housenumber' v='2'/>
            </way>
          </osm>
        OSM

        post api_ways_path, :params => osm, :headers => headers

        assert_response :bad_request, "adding new duplicate tags to a way should fail with 'bad request'"
        assert_equal "Element way/ has duplicate tags with key addr:housenumber", @response.body
      end
    end

    def test_create_race_condition
      user = create(:user)
      changeset = create(:changeset, :user => user)
      node = create(:node)
      auth_header = bearer_authorization_header user
      path = api_ways_path
      concurrency_level = 16

      threads = Array.new(concurrency_level) do
        Thread.new do
          osm = <<~OSM
            <osm>
              <way changeset='#{changeset.id}'>
                <nd ref='#{node.id}'/>
              </way>
            </osm>
          OSM
          post path, :params => osm, :headers => auth_header
        end
      end
      threads.each(&:join)

      changeset.reload
      assert_equal concurrency_level, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
      assert_equal concurrency_level, changeset.num_created_ways
    end

    # -------------------------------------
    # Test deleting ways.
    # -------------------------------------

    def test_destroy_when_unauthorized
      with_unchanging(:way) do |way|
        delete api_way_path(way)

        assert_response :unauthorized
      end
    end

    def test_destroy_without_payload_by_private_user
      with_unchanging(:way) do |way|
        with_unchanging_request([:data_public => false]) do |headers|
          delete api_way_path(way), :headers => headers

          assert_response :forbidden
        end
      end
    end

    def test_destroy_without_changeset_id_by_private_user
      with_unchanging(:way) do |way|
        with_unchanging_request([:data_public => false]) do |headers|
          osm = "<osm><way id='#{way.id}'/></osm>"

          delete api_way_path(way), :params => osm, :headers => headers

          assert_response :forbidden
        end
      end
    end

    def test_destroy_in_closed_changeset_by_private_user
      with_unchanging(:way) do |way|
        with_unchanging_request([:data_public => false], [:closed]) do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :forbidden
        end
      end
    end

    def test_destroy_in_missing_changeset_by_private_user
      with_unchanging(:way) do |way|
        with_unchanging_request([:data_public => false]) do |headers|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, 0

          delete api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :forbidden
        end
      end
    end

    def test_destroy_by_private_user
      with_unchanging(:way) do |way|
        with_unchanging_request([:data_public => false]) do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :forbidden
        end
      end
    end

    def test_destroy_deleted_way_by_private_user
      with_unchanging(:way, :deleted) do |way|
        with_unchanging_request([:data_public => false]) do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :forbidden
        end
      end
    end

    def test_destroy_way_in_relation_by_private_user
      with_unchanging(:way) do |way|
        create(:relation_member, :member => way)

        with_unchanging_request([:data_public => false]) do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :forbidden, "shouldn't be able to delete a way used in a relation (#{@response.body}), when done by a private user"
        end
      end
    end

    def test_destroy_missing_way_by_private_user
      with_unchanging_request([:data_public => false]) do |headers|
        delete api_way_path(0), :headers => headers

        assert_response :forbidden
      end
    end

    def test_destroy_without_payload
      with_unchanging(:way) do |way|
        with_unchanging_request do |headers|
          delete api_way_path(way), :headers => headers

          assert_response :bad_request
        end
      end
    end

    def test_destroy_without_changeset_id
      with_unchanging(:way) do |way|
        with_unchanging_request do |headers|
          osm = "<osm><way id='#{way.id}'/></osm>"

          delete api_way_path(way), :params => osm, :headers => headers

          assert_response :bad_request
        end
      end
    end

    def test_destroy_in_closed_changeset
      with_unchanging(:way) do |way|
        with_unchanging_request([], [:closed]) do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict
        end
      end
    end

    def test_destroy_in_missing_changeset
      with_unchanging(:way) do |way|
        with_unchanging_request do |headers|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, 0

          delete api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict
        end
      end
    end

    def test_destroy
      way = create(:way)

      with_request do |headers, changeset|
        osm_xml = xml_for_way way
        osm_xml = update_changeset osm_xml, changeset.id

        delete api_way_path(way), :params => osm_xml.to_s, :headers => headers

        assert_response :success

        response_way_version = @response.body.to_i
        assert_operator response_way_version, :>, way.version, "delete request should return a new version number for way"
        way.reload
        assert_not_predicate way, :visible?
        assert_equal response_way_version, way.version

        changeset.reload
        assert_equal 1, changeset.num_changes
        assert_predicate changeset, :num_type_changes_in_sync?
        assert_equal 1, changeset.num_deleted_ways
      end
    end

    def test_destroy_deleted_way
      with_unchanging(:way, :deleted) do |way|
        with_unchanging_request do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :gone
        end
      end
    end

    def test_destroy_way_in_relation
      with_unchanging(:way) do |way|
        relation_member = create(:relation_member, :member => way)

        with_unchanging_request do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :precondition_failed, "shouldn't be able to delete a way used in a relation (#{@response.body})"
          assert_equal "Precondition failed: Way #{way.id} is still used by relations #{relation_member.relation.id}.", @response.body
        end
      end
    end

    def test_destroy_missing_way_with_payload
      with_unchanging(:way) do |way|
        with_unchanging_request do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_way_path(0), :params => osm_xml.to_s, :headers => headers

          assert_response :not_found
        end
      end
    end

    # -------------------------------------
    # Test updating ways.
    # -------------------------------------

    def test_update_when_unauthorized
      with_unchanging(:way_with_nodes) do |way|
        osm_xml = xml_for_way way

        put api_way_path(way), :params => osm_xml.to_s

        assert_response :unauthorized
      end
    end

    def test_update_in_changeset_of_other_user_by_private_user
      with_unchanging(:way_with_nodes) do |way|
        other_user = create(:user)

        with_unchanging_request([:data_public => false], [:user => other_user]) do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_require_public_data "update with other user's changeset should be forbidden when date isn't public"
        end
      end
    end

    def test_update_in_closed_changeset_by_private_user
      with_unchanging(:way_with_nodes) do |way|
        with_unchanging_request([:data_public => false], [:closed]) do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_require_public_data "update with closed changeset should be forbidden, when data isn't public"
        end
      end
    end

    def test_update_in_missing_changeset_by_private_user
      with_unchanging(:way_with_nodes) do |way|
        with_unchanging_request([:data_public => false]) do |headers|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, 0

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_require_public_data "update with changeset=0 should be forbidden, when data isn't public"
        end
      end
    end

    def test_update_with_missing_node_by_private_user
      with_unchanging(:way) do |way|
        node = create(:node)
        create(:way_node, :way => way, :node => node)

        with_unchanging_request([:data_public => false]) do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = xml_replace_node osm_xml, node.id, 9999
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_require_public_data "way with non-existent node should be forbidden, when data isn't public"
        end
      end
    end

    def test_update_with_deleted_node_by_private_user
      with_unchanging(:way) do |way|
        node = create(:node)
        deleted_node = create(:node, :deleted)
        create(:way_node, :way => way, :node => node)

        with_unchanging_request([:data_public => false]) do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = xml_replace_node osm_xml, node.id, deleted_node.id
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_require_public_data "way with deleted node should be forbidden, when data isn't public"
        end
      end
    end

    def test_update_by_private_user
      with_unchanging(:way_with_nodes) do |way|
        with_unchanging_request([:data_public => false]) do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_require_public_data "should have failed with a forbidden when data isn't public"
        end
      end
    end

    def test_update_in_changeset_of_other_user
      with_unchanging(:way_with_nodes) do |way|
        other_user = create(:user)

        with_unchanging_request([], [:user => other_user]) do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict, "update with other user's changeset should be rejected"
        end
      end
    end

    def test_update_in_closed_changeset
      with_unchanging(:way_with_nodes) do |way|
        with_unchanging_request([], [:closed]) do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict, "update with closed changeset should be rejected"
        end
      end
    end

    def test_update_in_missing_changeset
      with_unchanging(:way_with_nodes) do |way|
        with_unchanging_request do |headers|
          osm_xml = xml_for_way way
          osm_xml = update_changeset osm_xml, 0

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict, "update with changeset=0 should be rejected"
        end
      end
    end

    def test_update_with_missing_node
      with_unchanging(:way) do |way|
        node = create(:node)
        create(:way_node, :way => way, :node => node)

        with_unchanging_request do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = xml_replace_node osm_xml, node.id, 9999
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :precondition_failed, "way with non-existent node should be rejected"
        end
      end
    end

    def test_update_with_deleted_node
      with_unchanging(:way) do |way|
        node = create(:node)
        deleted_node = create(:node, :deleted)
        create(:way_node, :way => way, :node => node)

        with_unchanging_request do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = xml_replace_node osm_xml, node.id, deleted_node.id
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :precondition_failed, "way with deleted node should be rejected"
        end
      end
    end

    def test_update_with_version_behind
      with_unchanging(:way_with_nodes, :version => 2) do |way|
        with_unchanging_request do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = xml_attr_rewrite osm_xml, "version", way.version - 1
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict, "should have failed on old version number"
        end
      end
    end

    def test_update_with_version_ahead
      with_unchanging(:way_with_nodes, :version => 2) do |way|
        with_unchanging_request do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = xml_attr_rewrite osm_xml, "version", way.version + 1
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict, "should have failed on skipped version number"
        end
      end
    end

    def test_update_with_invalid_version
      with_unchanging(:way_with_nodes) do |way|
        with_unchanging_request do |headers, changeset|
          osm_xml = xml_for_way way
          osm_xml = xml_attr_rewrite osm_xml, "version", "p1r4t3s!"
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict, "should not be able to put 'p1r4at3s!' in the version field"
        end
      end
    end

    def test_update_other_way
      with_unchanging(:way_with_nodes) do |way|
        with_unchanging(:way_with_nodes) do |other_way|
          with_unchanging_request do |headers, changeset|
            osm_xml = xml_for_way other_way
            osm_xml = update_changeset osm_xml, changeset.id

            put api_way_path(way), :params => osm_xml.to_s, :headers => headers

            assert_response :bad_request, "should not be able to update a way with a different ID from the XML"
          end
        end
      end
    end

    def test_update_with_invalid_osm_structure
      with_unchanging(:way_with_nodes) do |way|
        with_unchanging_request do |headers|
          osm = "<update/>"

          put api_way_path(way), :params => osm, :headers => headers

          assert_response :bad_request, "should not be able to update a way with non-OSM XML doc."
        end
      end
    end

    def test_update
      way = create(:way_with_nodes)

      with_request do |headers, changeset|
        osm_xml = xml_for_way way
        osm_xml = update_changeset osm_xml, changeset.id

        put api_way_path(way), :params => osm_xml.to_s, :headers => headers

        assert_response :success, "a valid update request failed"

        changeset.reload
        assert_equal 1, changeset.num_changes
        assert_predicate changeset, :num_type_changes_in_sync?
        assert_equal 1, changeset.num_modified_ways
      end
    end

    def test_update_with_new_tags_by_private_user
      with_unchanging(:way_with_nodes, :nodes_count => 2) do |way|
        with_unchanging_request([:data_public => false]) do |headers, changeset|
          tag_xml = XML::Node.new("tag")
          tag_xml["k"] = "new"
          tag_xml["v"] = "yes"

          osm_xml = xml_for_way way
          osm_xml.find("//osm/way").first << tag_xml
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :forbidden, "adding a tag to a way for a non-public should fail with 'forbidden'"
        end
      end
    end

    def test_update_with_new_tags
      way = create(:way_with_nodes, :nodes_count => 2)

      with_request do |headers, changeset|
        tag_xml = XML::Node.new("tag")
        tag_xml["k"] = "new"
        tag_xml["v"] = "yes"

        osm_xml = xml_for_way way
        osm_xml.find("//osm/way").first << tag_xml
        osm_xml = update_changeset osm_xml, changeset.id

        put api_way_path(way), :params => osm_xml.to_s, :headers => headers

        assert_response :success, "adding a new tag to a way should succeed"
        assert_equal way.version + 1, @response.body.to_i

        changeset.reload
        assert_equal 1, changeset.num_changes
        assert_predicate changeset, :num_type_changes_in_sync?
        assert_equal 1, changeset.num_modified_ways
      end
    end

    def test_update_with_duplicated_existing_tags_by_private_user
      with_unchanging(:way_with_nodes) do |way|
        create(:way_tag, :way => way, :k => "key_to_duplicate", :v => "value_to_duplicate")

        with_unchanging_request([:data_public => false]) do |headers, changeset|
          tag_xml = XML::Node.new("tag")
          tag_xml["k"] = "key_to_duplicate"
          tag_xml["v"] = "value_to_duplicate"

          osm_xml = xml_for_way way
          osm_xml.find("//osm/way").first << tag_xml
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :forbidden, "adding a duplicate tag to a way for a non-public should fail with 'forbidden'"
        end
      end
    end

    def test_update_with_duplicated_existing_tags
      with_unchanging(:way_with_nodes) do |way|
        create(:way_tag, :way => way, :k => "key_to_duplicate", :v => "value_to_duplicate")

        with_unchanging_request do |headers, changeset|
          tag_xml = XML::Node.new("tag")
          tag_xml["k"] = "key_to_duplicate"
          tag_xml["v"] = "value_to_duplicate"

          osm_xml = xml_for_way way
          osm_xml.find("//osm/way").first << tag_xml
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :bad_request, "adding a duplicate tag to a way should fail with 'bad request'"
          assert_equal "Element way/#{way.id} has duplicate tags with key key_to_duplicate", @response.body
        end
      end
    end

    def test_update_with_new_duplicate_tags_by_private_user
      with_unchanging(:way_with_nodes) do |way|
        with_unchanging_request([:data_public => false]) do |headers, changeset|
          tag_xml = XML::Node.new("tag")
          tag_xml["k"] = "i_am_a_duplicate"
          tag_xml["v"] = "foobar"

          osm_xml = xml_for_way way
          osm_xml.find("//osm/way").first << tag_xml.copy(true) << tag_xml
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :forbidden, "adding new duplicate tags to a way using a non-public user should fail with 'forbidden'"
        end
      end
    end

    def test_update_with_new_duplicate_tags
      with_unchanging(:way_with_nodes) do |way|
        with_unchanging_request do |headers, changeset|
          tag_xml = XML::Node.new("tag")
          tag_xml["k"] = "i_am_a_duplicate"
          tag_xml["v"] = "foobar"

          osm_xml = xml_for_way way
          osm_xml.find("//osm/way").first << tag_xml.copy(true) << tag_xml
          osm_xml = update_changeset osm_xml, changeset.id

          put api_way_path(way), :params => osm_xml.to_s, :headers => headers

          assert_response :bad_request, "adding new duplicate tags to a way should fail with 'bad request'"
          assert_equal "Element way/#{way.id} has duplicate tags with key i_am_a_duplicate", @response.body
        end
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

      # try creating a way
      xml = <<~OSM
        <osm>
          <way changeset='#{changeset.id}'>
            <nd ref='#{node1.id}'/>
            <nd ref='#{node2.id}'/>
          </way>
        </osm>
      OSM
      post api_ways_path, :params => xml, :headers => auth_header
      assert_response :success, "way create did not return success status"

      # get the id of the way we created
      wayid = @response.body

      # try updating the way, which should be rate limited
      xml = <<~OSM
        <osm>
          <way id='#{wayid}' version='1' changeset='#{changeset.id}'>
            <nd ref='#{node2.id}'/>
            <nd ref='#{node1.id}'/>
          </way>
        </osm>
      OSM
      put api_way_path(wayid), :params => xml, :headers => auth_header
      assert_response :too_many_requests, "way update did not hit rate limit"

      # try deleting the way, which should be rate limited
      xml = "<osm><way id='#{wayid}' version='2' changeset='#{changeset.id}'/></osm>"
      delete api_way_path(wayid), :params => xml, :headers => auth_header
      assert_response :too_many_requests, "way delete did not hit rate limit"

      # try creating a way, which should be rate limited
      xml = <<~OSM
        <osm>
          <way changeset='#{changeset.id}'>
            <nd ref='#{node1.id}'/>
            <nd ref='#{node2.id}'/>
          </way>
        </osm>
      OSM
      post api_ways_path, :params => xml, :headers => auth_header
      assert_response :too_many_requests, "way create did not hit rate limit"
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

      # try creating a way
      xml = <<~OSM
        <osm>
          <way changeset='#{changeset.id}'>
            <nd ref='#{node1.id}'/>
            <nd ref='#{node2.id}'/>
          </way>
        </osm>
      OSM
      post api_ways_path, :params => xml, :headers => auth_header
      assert_response :success, "way create did not return success status"

      # get the id of the way we created
      wayid = @response.body

      # try updating the way, which should be rate limited
      xml = <<~OSM
        <osm>
          <way id='#{wayid}' version='1' changeset='#{changeset.id}'>
            <nd ref='#{node2.id}'/>
            <nd ref='#{node1.id}'/>
          </way>
        </osm>
      OSM
      put api_way_path(wayid), :params => xml, :headers => auth_header
      assert_response :too_many_requests, "way update did not hit rate limit"

      # try deleting the way, which should be rate limited
      xml = "<osm><way id='#{wayid}' version='2' changeset='#{changeset.id}'/></osm>"
      delete api_way_path(wayid), :params => xml, :headers => auth_header
      assert_response :too_many_requests, "way delete did not hit rate limit"

      # try creating a way, which should be rate limited
      xml = <<~OSM
        <osm>
          <way changeset='#{changeset.id}'>
            <nd ref='#{node1.id}'/>
            <nd ref='#{node2.id}'/>
          </way>
        </osm>
      OSM
      post api_ways_path, :params => xml, :headers => auth_header
      assert_response :too_many_requests, "way create did not hit rate limit"
    end

    private

    def affected_models
      [Way, WayNode, WayTag,
       OldWay, OldWayNode, OldWayTag]
    end

    ##
    # update an attribute in the way element
    def xml_attr_rewrite(xml, name, value)
      xml.find("//osm/way").first[name] = value.to_s
      xml
    end

    ##
    # replace a node in a way element
    def xml_replace_node(xml, old_node, new_node)
      xml.find("//osm/way/nd[@ref='#{old_node}']").first["ref"] = new_node.to_s
      xml
    end
  end
end
