require "test_helper"

module Api
  module Ways
    class RelationsControllerTest < ActionDispatch::IntegrationTest
      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/way/1/relations", :method => :get },
          { :controller => "api/ways/relations", :action => "index", :way_id => "1" }
        )
        assert_routing(
          { :path => "/api/0.6/way/1/relations.json", :method => :get },
          { :controller => "api/ways/relations", :action => "index", :way_id => "1", :format => "json" }
        )
      end

      def test_index
        way = create(:way)
        # should include relations with that way as a member
        relation_with_way = create(:relation_member, :member => way).relation
        # should ignore relations without that way as a member
        _relation_without_way = create(:relation_member).relation
        # should ignore relations with the way involved indirectly, via a relation
        second_relation = create(:relation_member, :member => way).relation
        _super_relation = create(:relation_member, :member => second_relation).relation
        # should combine multiple relation_member references into just one relation entry
        create(:relation_member, :member => way, :relation => relation_with_way)
        # should not include deleted relations
        deleted_relation = create(:relation, :deleted)
        create(:relation_member, :member => way, :relation => deleted_relation)

        get api_way_relations_path(way)

        assert_response :success

        # count one osm element
        assert_select "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1

        # we should have only the expected number of relations
        expected_relations = [relation_with_way, second_relation]
        assert_select "osm>relation", expected_relations.size

        # and each of them should contain the element we originally searched for
        expected_relations.each do |containing_relation|
          # The relation should appear once, but the element could appear multiple times
          assert_select "osm>relation[id='#{containing_relation.id}']", 1
          assert_select "osm>relation[id='#{containing_relation.id}']>member[type='way'][ref='#{way.id}']"
        end
      end

      def test_index_json
        way = create(:way)
        containing_relation = create(:relation_member, :member => way).relation

        get api_way_relations_path(way, :format => "json")

        assert_response :success
        js = ActiveSupport::JSON.decode(@response.body)
        assert_not_nil js
        assert_equal 1, js["elements"].count
        js_relations = js["elements"].filter { |e| e["type"] == "relation" }
        assert_equal 1, js_relations.count
        assert_equal containing_relation.id, js_relations[0]["id"]
      end
    end
  end
end
