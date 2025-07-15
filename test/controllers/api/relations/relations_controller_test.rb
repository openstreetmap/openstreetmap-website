require "test_helper"

module Api
  module Relations
    class RelationsControllerTest < ActionDispatch::IntegrationTest
      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/relation/1/relations", :method => :get },
          { :controller => "api/relations/relations", :action => "index", :relation_id => "1" }
        )
        assert_routing(
          { :path => "/api/0.6/relation/1/relations.json", :method => :get },
          { :controller => "api/relations/relations", :action => "index", :relation_id => "1", :format => "json" }
        )
      end

      def test_index
        relation = create(:relation)
        # should include relations with that relation as a member
        relation_with_relation = create(:relation_member, :member => relation).relation
        # should ignore any relation without that relation as a member
        _relation_without_relation = create(:relation_member).relation
        # should ignore relations with the relation involved indirectly, via a relation
        second_relation = create(:relation_member, :member => relation).relation
        _super_relation = create(:relation_member, :member => second_relation).relation
        # should combine multiple relation_member references into just one relation entry
        create(:relation_member, :member => relation, :relation => relation_with_relation)
        # should not include deleted relations
        deleted_relation = create(:relation, :deleted)
        create(:relation_member, :member => relation, :relation => deleted_relation)

        get api_relation_relations_path(relation)

        assert_response :success

        # count one osm element
        assert_select "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1

        # we should have only the expected number of relations
        expected_relations = [relation_with_relation, second_relation]
        assert_select "osm>relation", expected_relations.size

        # and each of them should contain the element we originally searched for
        expected_relations.each do |containing_relation|
          # The relation should appear once, but the element could appear multiple times
          assert_select "osm>relation[id='#{containing_relation.id}']", 1
          assert_select "osm>relation[id='#{containing_relation.id}']>member[type='relation'][ref='#{relation.id}']"
        end
      end

      def test_index_json
        relation = create(:relation)
        containing_relation = create(:relation_member, :member => relation).relation

        get api_relation_relations_path(relation, :format => "json")

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
