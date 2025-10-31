# frozen_string_literal: true

require "application_system_test_case"

class ElementHistoryTest < ApplicationSystemTestCase
  test "shows history of a node" do
    node = create(:node, :with_history, :version => 2, :lat => 60, :lon => 30)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v2 = node.old_nodes.find_by(:version => 2)
    create(:old_node_tag, :old_node => node_v1, :k => "key", :v => "VALUE-ONE")
    create(:old_node_tag, :old_node => node_v2, :k => "key", :v => "VALUE-TWO")
    node_v1.update(:lat => 59, :lon => 29)

    visit node_history_path(node)

    within_sidebar do
      v2_heading = find :element, "h4", :text => "Version #2"
      v1_heading = find :element, "h4", :text => "Version #1", :below => v2_heading

      assert_css "td", :text => "VALUE-TWO", :below => v2_heading, :above => v1_heading
      assert_css "td", :text => "VALUE-ONE", :below => v1_heading
      assert_text(/Location: 60\.\d+, 30\.\d+/)
      assert_text(/Location: 59\.\d+, 29\.\d+/)

      assert_link "Node", :href => node_path(node)
      assert_no_link "History", :exact => true
      assert_no_link "Unredacted History"
    end
  end

  test "shows history of a way" do
    way = create(:way, :with_history, :version => 2)
    way_v1 = way.old_ways.find_by(:version => 1)
    way_v2 = way.old_ways.find_by(:version => 2)
    create(:old_way_tag, :old_way => way_v1, :k => "key", :v => "VALUE-ONE")
    create(:old_way_tag, :old_way => way_v2, :k => "key", :v => "VALUE-TWO")

    visit way_history_path(way)

    within_sidebar do
      v2_heading = find :element, "h4", :text => "Version #2"
      v1_heading = find :element, "h4", :text => "Version #1", :below => v2_heading

      assert_css "td", :text => "VALUE-TWO", :below => v2_heading, :above => v1_heading
      assert_css "td", :text => "VALUE-ONE", :below => v1_heading

      assert_link "Way", :href => way_path(way)
      assert_no_link "History", :exact => true
      assert_no_link "Unredacted History"
    end
  end

  test "shows history of a relation" do
    relation = create(:relation, :with_history, :version => 2)
    relation_v1 = relation.old_relations.find_by(:version => 1)
    relation_v2 = relation.old_relations.find_by(:version => 2)
    create(:old_relation_tag, :old_relation => relation_v1, :k => "key", :v => "VALUE-ONE")
    create(:old_relation_tag, :old_relation => relation_v2, :k => "key", :v => "VALUE-TWO")

    visit relation_history_path(relation)

    within_sidebar do
      v2_heading = find :element, "h4", :text => "Version #2"
      v1_heading = find :element, "h4", :text => "Version #1", :below => v2_heading

      assert_css "td", :text => "VALUE-TWO", :below => v2_heading, :above => v1_heading
      assert_css "td", :text => "VALUE-ONE", :below => v1_heading

      assert_link "Relation", :href => relation_path(relation)
      assert_no_link "History", :exact => true
      assert_no_link "Unredacted History"
    end
  end

  test "shows history of a node to a regular user" do
    node = create(:node, :with_history)

    visit node_history_path(node)

    within_sidebar do
      assert_link "Node", :href => node_path(node)
      assert_no_link "History", :exact => true
      assert_no_link "Unredacted History"
    end
  end

  test "shows history of a way to a regular user" do
    way = create(:way, :with_history)

    visit way_history_path(way)

    within_sidebar do
      assert_link "Way", :href => way_path(way)
      assert_no_link "History", :exact => true
      assert_no_link "Unredacted History"
    end
  end

  test "shows history of a relation to a regular user" do
    relation = create(:relation, :with_history)

    visit relation_history_path(relation)

    within_sidebar do
      assert_link "Relation", :href => relation_path(relation)
      assert_no_link "History", :exact => true
      assert_no_link "Unredacted History"
    end
  end

  test "shows history of a node with one redacted version" do
    node = create(:node, :with_history, :version => 2, :lat => 60, :lon => 30)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v2 = node.old_nodes.find_by(:version => 2)
    create(:old_node_tag, :old_node => node_v1, :k => "key", :v => "VALUE-ONE")
    create(:old_node_tag, :old_node => node_v2, :k => "key", :v => "VALUE-TWO")
    node_v1.update(:lat => 59, :lon => 29)
    node_v1.redact!(create(:redaction))

    visit node_history_path(node)

    within_sidebar do
      assert_css "h4", :text => "Version #2"
      assert_css "td", :text => "VALUE-TWO"
      assert_no_css "td", :text => "VALUE-ONE"
      assert_text(/Location: 60\.\d+, 30\.\d+/)
      assert_no_text(/Location: 59\.\d+, 29\.\d+/)
      assert_text "Version 1 of this node cannot be shown"

      assert_link "Node", :href => node_path(node)
      assert_no_link "History", :exact => true
      assert_no_link "Unredacted History"
    end
  end

  test "shows history of a way with one redacted version" do
    way = create(:way, :with_history, :version => 2)
    way_v1 = way.old_ways.find_by(:version => 1)
    way_v2 = way.old_ways.find_by(:version => 2)
    create(:old_way_tag, :old_way => way_v1, :k => "key", :v => "VALUE-ONE")
    create(:old_way_tag, :old_way => way_v2, :k => "key", :v => "VALUE-TWO")
    way_v1.redact!(create(:redaction))

    visit way_history_path(way)

    within_sidebar do
      assert_css "h4", :text => "Version #2"
      assert_css "td", :text => "VALUE-TWO"
      assert_no_css "td", :text => "VALUE-ONE"
      assert_text "Version 1 of this way cannot be shown"

      assert_link "Way", :href => way_path(way)
      assert_no_link "History", :exact => true
      assert_no_link "Unredacted History"
    end
  end

  test "shows history of a relation with one redacted version" do
    relation = create(:relation, :with_history, :version => 2)
    relation_v1 = relation.old_relations.find_by(:version => 1)
    relation_v2 = relation.old_relations.find_by(:version => 2)
    create(:old_relation_tag, :old_relation => relation_v1, :k => "key", :v => "VALUE-ONE")
    create(:old_relation_tag, :old_relation => relation_v2, :k => "key", :v => "VALUE-TWO")
    relation_v1.redact!(create(:redaction))

    visit relation_history_path(relation)

    within_sidebar do
      assert_css "h4", :text => "Version #2"
      assert_css "td", :text => "VALUE-TWO"
      assert_no_css "td", :text => "VALUE-ONE"
      assert_text "Version 1 of this relation cannot be shown"

      assert_link "Relation", :href => relation_path(relation)
      assert_no_link "History", :exact => true
      assert_no_link "Unredacted History"
    end
  end

  test "shows history of a node with one redacted version to a moderator" do
    node = create(:node, :with_history, :version => 2, :lat => 60, :lon => 30)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v2 = node.old_nodes.find_by(:version => 2)
    create(:old_node_tag, :old_node => node_v1, :k => "key", :v => "VALUE-ONE")
    create(:old_node_tag, :old_node => node_v2, :k => "key", :v => "VALUE-TWO")
    node_v1.update(:lat => 59, :lon => 29)
    node_v1.redact!(create(:redaction))

    sign_in_as(create(:moderator_user))
    visit node_history_path(node)

    within_sidebar do
      assert_css "td", :text => "VALUE-TWO"
      assert_no_css "td", :text => "VALUE-ONE"
      assert_text(/Location: 60\.\d+, 30\.\d+/)
      assert_no_text(/Location: 59\.\d+, 29\.\d+/)
      assert_text "Version 1 of this node cannot be shown"

      assert_link "Node", :href => node_path(node)
      assert_no_link "History", :exact => true
      assert_link "Unredacted History"

      click_on "Unredacted History"

      assert_css "td", :text => "VALUE-TWO"
      assert_css "td", :text => "VALUE-ONE"
      assert_text(/Location: 60\.\d+, 30\.\d+/)
      assert_text(/Location: 59\.\d+, 29\.\d+/)
      assert_no_text "Version 1 of this node cannot be shown"

      assert_link "Node", :href => node_path(node)
      assert_link "History", :exact => true
      assert_no_link "Unredacted History"

      click_on "History", :exact => true

      assert_text "Version 1 of this node cannot be shown"
    end
  end

  test "shows history of a way with one redacted version to a moderator" do
    way = create(:way, :with_history, :version => 2)
    way_v1 = way.old_ways.find_by(:version => 1)
    way_v2 = way.old_ways.find_by(:version => 2)
    create(:old_way_tag, :old_way => way_v1, :k => "key", :v => "VALUE-ONE")
    create(:old_way_tag, :old_way => way_v2, :k => "key", :v => "VALUE-TWO")
    way_v1.redact!(create(:redaction))

    sign_in_as(create(:moderator_user))
    visit way_history_path(way)

    within_sidebar do
      assert_css "td", :text => "VALUE-TWO"
      assert_no_css "td", :text => "VALUE-ONE"
      assert_text "Version 1 of this way cannot be shown"

      assert_link "Way", :href => way_path(way)
      assert_no_link "History", :exact => true
      assert_link "Unredacted History"

      click_on "Unredacted History"

      assert_css "td", :text => "VALUE-TWO"
      assert_css "td", :text => "VALUE-ONE"
      assert_no_text "Version 1 of this way cannot be shown"

      assert_link "Way", :href => way_path(way)
      assert_link "History", :exact => true
      assert_no_link "Unredacted History"

      click_on "History", :exact => true

      assert_text "Version 1 of this way cannot be shown"
    end
  end

  test "shows history of a relation with one redacted version to a moderator" do
    relation = create(:relation, :with_history, :version => 2)
    relation_v1 = relation.old_relations.find_by(:version => 1)
    relation_v2 = relation.old_relations.find_by(:version => 2)
    create(:old_relation_tag, :old_relation => relation_v1, :k => "key", :v => "VALUE-ONE")
    create(:old_relation_tag, :old_relation => relation_v2, :k => "key", :v => "VALUE-TWO")
    relation_v1.redact!(create(:redaction))

    sign_in_as(create(:moderator_user))
    visit relation_history_path(relation)

    within_sidebar do
      assert_css "td", :text => "VALUE-TWO"
      assert_no_css "td", :text => "VALUE-ONE"
      assert_text "Version 1 of this relation cannot be shown"

      assert_link "Relation", :href => relation_path(relation)
      assert_no_link "History", :exact => true
      assert_link "Unredacted History"

      click_on "Unredacted History"

      assert_css "td", :text => "VALUE-TWO"
      assert_css "td", :text => "VALUE-ONE"
      assert_no_text "Version 1 of this relation cannot be shown"

      assert_link "Relation", :href => relation_path(relation)
      assert_link "History", :exact => true
      assert_no_link "Unredacted History"

      click_on "History", :exact => true

      assert_text "Version 1 of this relation cannot be shown"
    end
  end

  test "can view node history pages" do
    node = create(:node, :with_history, :version => 41)

    visit node_path(node)

    check_element_history_pages(->(v) { old_node_path(node, v) })
  end

  test "can view way history pages" do
    way = create(:way, :with_history, :version => 41)

    visit way_path(way)

    check_element_history_pages(->(v) { old_way_path(way, v) })
  end

  test "can view relation history pages" do
    relation = create(:relation, :with_history, :version => 41)

    visit relation_path(relation)

    check_element_history_pages(->(v) { old_relation_path(relation, v) })
  end

  private

  def check_element_history_pages(get_path)
    within_sidebar do
      click_on "History", :exact => true

      41.downto(22) do |v|
        assert_link v.to_s, :href => get_path.call(v)
      end

      click_on "Older Versions"

      41.downto(2) do |v|
        assert_link v.to_s, :href => get_path.call(v)
      end

      click_on "Older Versions"

      41.downto(1) do |v|
        assert_link v.to_s, :href => get_path.call(v)
      end

      assert_no_link "Older Versions"
    end
  end
end
