require "application_system_test_case"

class BrowseTest < ApplicationSystemTestCase
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

    find("#map [aria-label='Share']").click
    share_url = find_by_id("long_input").value
    assert_match %r{map=\d+/59\.\d+/29\.\d+}, share_url
  end
end
