# frozen_string_literal: true

require "application_system_test_case"

class ElementCurrentVersionTest < ApplicationSystemTestCase
  test "shows a node with one version" do
    node = create(:node, :lat => 60, :lon => 30)

    visit node_path(node)

    within_sidebar do
      assert_css "h2", :text => "Node: #{node.id}"
      within "h4", :text => "Version #1" do
        assert_link "1", :href => old_node_path(node, 1)
      end
      assert_text(/Location: 60\.\d+, 30\.\d+/)
      assert_no_text "Deleted"

      assert_link "Download XML", :href => api_node_path(node)
      assert_link "History", :exact => true, :href => node_history_path(node)
      assert_no_link "Unredacted History"
    end
  end

  test "shows a way with one version" do
    way = create(:way)

    visit way_path(way)

    within_sidebar do
      assert_css "h2", :text => "Way: #{way.id}"
      within "h4", :text => "Version #1" do
        assert_link "1", :href => old_way_path(way, 1)
      end
      assert_no_text "Deleted"

      assert_link "Download XML", :href => api_way_path(way)
      assert_link "History", :exact => true, :href => way_history_path(way)
      assert_no_link "Unredacted History"
    end
  end

  test "shows a relation with one version" do
    relation = create(:relation)

    visit relation_path(relation)

    within_sidebar do
      assert_css "h2", :text => "Relation: #{relation.id}"
      within "h4", :text => "Version #1" do
        assert_link "1", :href => old_relation_path(relation, 1)
      end
      assert_no_text "Deleted"

      assert_link "Download XML", :href => api_relation_path(relation)
      assert_link "History", :exact => true, :href => relation_history_path(relation)
      assert_no_link "Unredacted History"
    end
  end

  test "shows a node with two versions" do
    node = create(:node, :with_history, :lat => 60, :lon => 30, :version => 2)

    visit node_path(node)

    within_sidebar do
      assert_css "h2", :text => "Node: #{node.id}"
      within "h4", :text => "Version #2" do
        assert_link "2", :href => old_node_path(node, 2)
      end
      assert_text(/Location: 60\.\d+, 30\.\d+/)
      assert_no_text "Deleted"

      assert_link "Download XML", :href => api_node_path(node)
      assert_link "History", :exact => true, :href => node_history_path(node)
      assert_no_link "Unredacted History"
      assert_link "Version #1", :href => old_node_path(node, 1)
      assert_link "Version #2", :href => old_node_path(node, 2)
    end
  end

  test "shows a way with two versions" do
    way = create(:way, :version => 2)

    visit way_path(way)

    within_sidebar do
      assert_css "h2", :text => "Way: #{way.id}"
      within "h4", :text => "Version #2" do
        assert_link "2", :href => old_way_path(way, 2)
      end
      assert_no_text "Deleted"

      assert_link "Download XML", :href => api_way_path(way)
      assert_link "History", :exact => true, :href => way_history_path(way)
      assert_no_link "Unredacted History"
      assert_link "Version #1", :href => old_way_path(way, 1)
      assert_link "Version #2", :href => old_way_path(way, 2)
    end
  end

  test "shows a relation with two versions" do
    relation = create(:relation, :version => 2)

    visit relation_path(relation)

    within_sidebar do
      assert_css "h2", :text => "Relation: #{relation.id}"
      within "h4", :text => "Version #2" do
        assert_link "2", :href => old_relation_path(relation, 2)
      end
      assert_no_text "Deleted"

      assert_link "Download XML", :href => api_relation_path(relation)
      assert_link "History", :exact => true, :href => relation_history_path(relation)
      assert_no_link "Unredacted History"
      assert_link "Version #1", :href => old_relation_path(relation, 1)
      assert_link "Version #2", :href => old_relation_path(relation, 2)
    end
  end

  test "shows a deleted node" do
    node = create(:node, :with_history, :lat => 60, :lon => 30, :visible => false, :version => 2)

    visit node_path(node)

    within_sidebar do
      assert_css "h2", :text => "Node: #{node.id}"
      within "h4", :text => "Version #2" do
        assert_link "2", :href => old_node_path(node, 2)
      end
      assert_no_text "Location"
      assert_text "Deleted"

      assert_no_link "Download XML"
      assert_link "History", :exact => true, :href => node_history_path(node)
      assert_no_link "Unredacted History"
    end
  end

  test "shows a deleted way" do
    way = create(:way, :visible => false, :version => 2)

    visit way_path(way)

    within_sidebar do
      assert_css "h2", :text => "Way: #{way.id}"
      within "h4", :text => "Version #2" do
        assert_link "2", :href => old_way_path(way, 2)
      end
      assert_text "Deleted"

      assert_no_link "Download XML"
      assert_link "History", :exact => true, :href => way_history_path(way)
      assert_no_link "Unredacted History"
    end
  end

  test "shows a deleted relation" do
    relation = create(:relation, :visible => false, :version => 2)

    visit relation_path(relation)

    within_sidebar do
      assert_css "h2", :text => "Relation: #{relation.id}"
      within "h4", :text => "Version #2" do
        assert_link "2", :href => old_relation_path(relation, 2)
      end
      assert_text "Deleted"

      assert_no_link "Download XML"
      assert_link "History", :exact => true, :href => relation_history_path(relation)
      assert_no_link "Unredacted History"
    end
  end

  test "shows node navigation to regular users" do
    node = create(:node, :with_history)

    sign_in_as(create(:user))
    visit node_path(node)

    within_sidebar do
      assert_link "History", :exact => true, :href => node_history_path(node)
      assert_no_link "Unredacted History"
    end
  end

  test "shows way navigation to regular users" do
    way = create(:way, :with_history)

    sign_in_as(create(:user))
    visit way_path(way)

    within_sidebar do
      assert_link "History", :exact => true, :href => way_history_path(way)
      assert_no_link "Unredacted History"
    end
  end

  test "shows relation navigation to regular users" do
    relation = create(:relation, :with_history)

    sign_in_as(create(:user))
    visit relation_path(relation)

    within_sidebar do
      assert_link "History", :exact => true, :href => relation_history_path(relation)
      assert_no_link "Unredacted History"
    end
  end

  test "shows node navigation to moderators" do
    node = create(:node, :with_history)

    sign_in_as(create(:moderator_user))
    visit node_path(node)

    within_sidebar do
      assert_link "History", :exact => true, :href => node_history_path(node)
      assert_link "Unredacted History", :href => node_history_path(node, :show_redactions => true)
    end
  end

  test "shows way navigation to moderators" do
    way = create(:way, :with_history)

    sign_in_as(create(:moderator_user))
    visit way_path(way)

    within_sidebar do
      assert_link "History", :exact => true, :href => way_history_path(way)
      assert_link "Unredacted History", :href => way_history_path(way, :show_redactions => true)
    end
  end

  test "shows relation navigation to moderators" do
    relation = create(:relation, :with_history)

    sign_in_as(create(:moderator_user))
    visit relation_path(relation)

    within_sidebar do
      assert_link "History", :exact => true, :href => relation_history_path(relation)
      assert_link "Unredacted History", :href => relation_history_path(relation, :show_redactions => true)
    end
  end

  test "shows a link to containing relation of a node" do
    node = create(:node)
    containing_relation = create(:relation)
    create(:relation_member, :relation => containing_relation, :member => node)

    visit node_path(node)

    within_sidebar do
      assert_link :href => relation_path(containing_relation)
    end
  end

  test "shows a link to containing relation of a way" do
    way = create(:way)
    containing_relation = create(:relation)
    create(:relation_member, :relation => containing_relation, :member => way)

    visit way_path(way)

    within_sidebar do
      assert_link :href => relation_path(containing_relation)
    end
  end

  test "shows a link to containing relation of a relation" do
    relation = create(:relation)
    containing_relation = create(:relation)
    create(:relation_member, :relation => containing_relation, :member => relation)

    visit relation_path(relation)

    within_sidebar do
      assert_link :href => relation_path(containing_relation)
    end
  end

  test "relation member nodes should be visible on the map when viewing relations" do
    relation = create(:relation)
    node = create(:node)
    create(:relation_member, :relation => relation, :member => node)

    visit relation_path(relation)

    assert_selector "#map .leaflet-overlay-pane path"
  end

  test "map should center on a viewed node" do
    node = create(:node, :lat => 59.55555, :lon => 29.55555)

    visit node_path(node)

    within "#map" do
      click_on "Share"
    end

    share_url = find_by_id("long_input").value
    assert_match %r{map=\d+/59\.\d+/29\.\d+}, share_url
  end
end
