# frozen_string_literal: true

require "application_system_test_case"

class ElementOldVersionTest < ApplicationSystemTestCase
  test "shows a node with one version" do
    node = create(:node, :with_history, :lat => 60, :lon => 30)

    visit old_node_path(node, 1)

    within_sidebar do
      assert_css "h2", :text => "Node: #{node.id}"
      assert_css "h4", :text => "Version #1"
      assert_text(/Location: 60\.\d+, 30\.\d+/)

      assert_link "Download XML", :href => api_node_version_path(node, 1)
      assert_link "Node", :href => node_path(node)
      assert_link "History", :exact => true, :href => node_history_path(node)
    end
  end

  test "shows a way with one version" do
    way = create(:way, :with_history)

    visit old_way_path(way, 1)

    within_sidebar do
      assert_css "h2", :text => "Way: #{way.id}"
      assert_css "h4", :text => "Version #1"

      assert_link "Download XML", :href => api_way_version_path(way, 1)
      assert_link "Way", :href => way_path(way)
      assert_link "History", :exact => true, :href => way_history_path(way)
    end
  end

  test "shows a relation with one version" do
    relation = create(:relation, :with_history)

    visit old_relation_path(relation, 1)

    within_sidebar do
      assert_css "h2", :text => "Relation: #{relation.id}"
      assert_css "h4", :text => "Version #1"

      assert_link "Download XML", :href => api_relation_version_path(relation, 1)
      assert_link "Relation", :href => relation_path(relation)
      assert_link "History", :exact => true, :href => relation_history_path(relation)
    end
  end

  test "shows a node with two versions" do
    node = create(:node, :with_history, :version => 2, :lat => 60, :lon => 30)
    node.old_nodes.find_by(:version => 1).update(:lat => 59, :lon => 29)

    visit old_node_path(node, 1)

    within_sidebar do
      assert_css "h2", :text => "Node: #{node.id}"
      assert_css "h4", :text => "Version #1"
      assert_text(/Location: 59\.\d+, 29\.\d+/)

      assert_link "Download XML", :href => api_node_version_path(node, 1)
      assert_link "Node", :href => node_path(node)
      assert_link "History", :exact => true, :href => node_history_path(node)

      click_on "Version #2"

      assert_css "h2", :text => "Node: #{node.id}"
      assert_css "h4", :text => "Version #2"
      assert_text(/Location: 60\.\d+, 30\.\d+/)

      assert_link "Download XML", :href => api_node_version_path(node, 2)
      assert_link "Node", :href => node_path(node)
      assert_link "History", :exact => true, :href => node_history_path(node)
    end
  end

  test "shows a way with two versions" do
    way = create(:way, :with_history, :version => 2)

    visit old_way_path(way, 1)

    within_sidebar do
      assert_css "h2", :text => "Way: #{way.id}"
      assert_css "h4", :text => "Version #1"

      assert_link "Download XML", :href => api_way_version_path(way, 1)
      assert_link "Way", :href => way_path(way)
      assert_link "History", :exact => true, :href => way_history_path(way)

      click_on "Version #2"

      assert_css "h2", :text => "Way: #{way.id}"
      assert_css "h4", :text => "Version #2"

      assert_link "Download XML", :href => api_way_version_path(way, 2)
      assert_link "Way", :href => way_path(way)
      assert_link "History", :exact => true, :href => way_history_path(way)
    end
  end

  test "shows a relation with two versions" do
    relation = create(:relation, :with_history, :version => 2)

    visit old_relation_path(relation, 1)

    within_sidebar do
      assert_css "h2", :text => "Relation: #{relation.id}"
      assert_css "h4", :text => "Version #1"

      assert_link "Download XML", :href => api_relation_version_path(relation, 1)
      assert_link "Relation", :href => relation_path(relation)
      assert_link "History", :exact => true, :href => relation_history_path(relation)

      click_on "Version #2"

      assert_css "h2", :text => "Relation: #{relation.id}"
      assert_css "h4", :text => "Version #2"

      assert_link "Download XML", :href => api_relation_version_path(relation, 2)
      assert_link "Relation", :href => relation_path(relation)
      assert_link "History", :exact => true, :href => relation_history_path(relation)
    end
  end

  test "show a redacted node version" do
    node = create_redacted_node

    visit old_node_path(node, 1)

    within_sidebar do
      assert_css "h2", :text => "Node: #{node.id}"
      assert_text "Version 1 of this node cannot be shown"
      assert_no_text "Location"
      assert_no_text "TOP SECRET"

      assert_no_link "Download XML"
      assert_no_link "View Redacted Data"
      assert_link "Node", :href => node_path(node)
      assert_link "History", :exact => true, :href => node_history_path(node)
    end
  end

  test "show a redacted way version" do
    way = create_redacted_way

    visit old_way_path(way, 1)

    within_sidebar do
      assert_css "h2", :text => "Way: #{way.id}"
      assert_text "Version 1 of this way cannot be shown"
      assert_no_text "Location"
      assert_no_text "TOP SECRET"

      assert_no_link "Download XML"
      assert_no_link "View Redacted Data"
      assert_link "Way", :href => way_path(way)
      assert_link "History", :exact => true, :href => way_history_path(way)
    end
  end

  test "show a redacted relation version" do
    relation = create_redacted_relation

    visit old_relation_path(relation, 1)

    within_sidebar do
      assert_css "h2", :text => "Relation: #{relation.id}"
      assert_text "Version 1 of this relation cannot be shown"
      assert_no_text "Location"
      assert_no_text "TOP SECRET"

      assert_no_link "Download XML"
      assert_no_link "View Redacted Data"
      assert_link "Relation", :href => relation_path(relation)
      assert_link "History", :exact => true, :href => relation_history_path(relation)
    end
  end

  test "show a redacted node version to a regular user" do
    node = create_redacted_node

    sign_in_as(create(:user))
    visit old_node_path(node, 1)

    within_sidebar do
      assert_css "h2", :text => "Node: #{node.id}"
      assert_text "Version 1 of this node cannot be shown"
      assert_no_text "Location"
      assert_no_text "TOP SECRET"

      assert_no_link "Download XML"
      assert_no_link "View Redacted Data"
      assert_link "Node", :href => node_path(node)
      assert_link "History", :exact => true, :href => node_history_path(node)
    end
  end

  test "show a redacted way version to a regular user" do
    way = create_redacted_way

    sign_in_as(create(:user))
    visit old_way_path(way, 1)

    within_sidebar do
      assert_css "h2", :text => "Way: #{way.id}"
      assert_text "Version 1 of this way cannot be shown"
      assert_no_text "Location"
      assert_no_text "TOP SECRET"

      assert_no_link "Download XML"
      assert_no_link "View Redacted Data"
      assert_link "Way", :href => way_path(way)
      assert_link "History", :exact => true, :href => way_history_path(way)
    end
  end

  test "show a redacted relation version to a regular user" do
    relation = create_redacted_relation

    sign_in_as(create(:user))
    visit old_relation_path(relation, 1)

    within_sidebar do
      assert_css "h2", :text => "Relation: #{relation.id}"
      assert_text "Version 1 of this relation cannot be shown"
      assert_no_text "Location"
      assert_no_text "TOP SECRET"

      assert_no_link "Download XML"
      assert_no_link "View Redacted Data"
      assert_link "Relation", :href => relation_path(relation)
      assert_link "History", :exact => true, :href => relation_history_path(relation)
    end
  end

  test "show a redacted node version to a moderator" do
    node = create_redacted_node

    sign_in_as(create(:moderator_user))
    visit old_node_path(node, 1)

    within_sidebar do
      assert_css "h2", :text => "Node: #{node.id}"
      assert_text "Version 1 of this node cannot be shown"
      assert_no_text "Location"
      assert_no_text "TOP SECRET"

      assert_no_link "Download XML"
      assert_link "View Redacted Data"
      assert_no_link "View Redaction Message"
      assert_link "Node", :href => node_path(node)
      assert_link "History", :exact => true, :href => node_history_path(node)

      click_on "View Redacted Data"

      assert_css "h2", :text => "Node: #{node.id}"
      assert_css "h4", :text => "Redacted Version #1"
      assert_text(/Location: 59\.\d+, 29\.\d+/)
      assert_text "TOP SECRET"

      assert_no_link "Download XML"
      assert_no_link "View Redacted Data"
      assert_link "View Redaction Message"
      assert_link "Node", :href => node_path(node)
      assert_link "History", :exact => true, :href => node_history_path(node)

      click_on "View Redaction Message"

      assert_text "Version 1 of this node cannot be shown"
    end
  end

  test "show a redacted way version to a moderator" do
    way = create_redacted_way

    sign_in_as(create(:moderator_user))
    visit old_way_path(way, 1)

    within_sidebar do
      assert_css "h2", :text => "Way: #{way.id}"
      assert_text "Version 1 of this way cannot be shown"
      assert_no_text "Location"
      assert_no_text "TOP SECRET"

      assert_no_link "Download XML"
      assert_link "View Redacted Data"
      assert_no_link "View Redaction Message"
      assert_link "Way", :href => way_path(way)
      assert_link "History", :exact => true, :href => way_history_path(way)

      click_on "View Redacted Data"

      assert_css "h2", :text => "Way: #{way.id}"
      assert_css "h4", :text => "Redacted Version #1"
      assert_text "TOP SECRET"

      assert_no_link "Download XML"
      assert_no_link "View Redacted Data"
      assert_link "View Redaction Message"
      assert_link "Way", :href => way_path(way)
      assert_link "History", :exact => true, :href => way_history_path(way)

      click_on "View Redaction Message"

      assert_text "Version 1 of this way cannot be shown"
    end
  end

  test "show a redacted relation version to a moderator" do
    relation = create_redacted_relation

    sign_in_as(create(:moderator_user))
    visit old_relation_path(relation, 1)

    within_sidebar do
      assert_css "h2", :text => "Relation: #{relation.id}"
      assert_text "Version 1 of this relation cannot be shown"
      assert_no_text "Location"
      assert_no_text "TOP SECRET"

      assert_no_link "Download XML"
      assert_link "View Redacted Data"
      assert_no_link "View Redaction Message"
      assert_link "Relation", :href => relation_path(relation)
      assert_link "History", :exact => true, :href => relation_history_path(relation)

      click_on "View Redacted Data"

      assert_css "h2", :text => "Relation: #{relation.id}"
      assert_css "h4", :text => "Redacted Version #1"
      assert_text "TOP SECRET"

      assert_no_link "Download XML"
      assert_no_link "View Redacted Data"
      assert_link "View Redaction Message"
      assert_link "Relation", :href => relation_path(relation)
      assert_link "History", :exact => true, :href => relation_history_path(relation)

      click_on "View Redaction Message"

      assert_text "Version 1 of this relation cannot be shown"
    end
  end

  test "navigates between multiple node versions" do
    node = create(:node, :with_history, :version => 5)

    visit node_path(node)

    within_sidebar do
      assert_css "h4", :text => "Version #5"

      click_on "Version #3"

      assert_css "h4", :text => "Version #3"

      click_on "Version #2"

      assert_css "h4", :text => "Version #2"

      click_on "Version #4"

      assert_css "h4", :text => "Version #4"
    end
  end

  private

  def create_redacted_node
    create(:node, :with_history, :version => 2, :lat => 60, :lon => 30) do |node|
      node_v1 = node.old_nodes.find_by(:version => 1)
      node_v1.update(:lat => 59, :lon => 29)
      create(:old_node_tag, :old_node => node_v1, :k => "name", :v => "TOP SECRET")
      node_v1.redact!(create(:redaction))
    end
  end

  def create_redacted_way
    create(:way, :with_history, :version => 2) do |way|
      way_v1 = way.old_ways.find_by(:version => 1)
      create(:old_way_tag, :old_way => way_v1, :k => "name", :v => "TOP SECRET")
      way_v1.redact!(create(:redaction))
    end
  end

  def create_redacted_relation
    create(:relation, :with_history, :version => 2) do |relation|
      relation_v1 = relation.old_relations.find_by(:version => 1)
      create(:old_relation_tag, :old_relation => relation_v1, :k => "name", :v => "TOP SECRET")
      relation_v1.redact!(create(:redaction))
    end
  end
end
