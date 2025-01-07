require "application_system_test_case"

class BrowseTest < ApplicationSystemTestCase
  test "relation member nodes should be visible on the map when viewing relations" do
    relation = create(:relation)
    node = create(:node)
    create(:relation_member, :relation => relation, :member => node)

    visit relation_path(relation)

    assert_selector "#map .leaflet-overlay-pane path"
  end
end
