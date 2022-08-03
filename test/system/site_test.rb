require "application_system_test_case"

class SiteTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit "/"

    assert_selector "h1", :text => "OpenStreetMap"
  end

  test "tooltip shows for Layers button" do
    visit "/"

    assert_no_selector ".tooltip"
    button = find ".control-layers .control-button"
    button.hover
    assert_selector ".tooltip", :text => "Layers"
  end

  test "tooltip shows for Map Key button on Standard layer" do
    visit "/"

    assert_no_selector ".tooltip"
    button = find ".control-key .control-button"
    button.hover
    tooltip = find ".tooltip"
    tooltip.assert_text "Map Key"
    tooltip.assert_no_text "not available"
  end

  test "tooltip shows for Map Key button on a layer without a key provided" do
    visit "/#layers=Y" # assumes that CyclOSM layer has no map key

    assert_no_selector ".tooltip"
    button = find ".control-key .control-button"
    button.hover
    tooltip = find ".tooltip"
    tooltip.assert_text "Map Key"
    tooltip.assert_text "not available"
  end

  test "tooltip shows for query button when zoomed in" do
    visit "/#map=14/0/0"

    assert_no_selector ".tooltip"
    button = find ".control-query .control-button"
    button.hover
    tooltip = find ".tooltip"
    tooltip.assert_text "Query features"
    tooltip.assert_no_text "Zoom in"
  end

  test "tooltip shows for query button when zoomed out" do
    visit "/#map=10/0/0"

    assert_no_selector ".tooltip"
    button = find ".control-query .control-button"
    button.hover
    tooltip = find ".tooltip"
    tooltip.assert_text "Zoom in to query features"
  end

  test "tooltip shows for edit button when zoomed out" do
    visit "/#map=11/0/0"

    assert_no_selector ".tooltip"
    button = find "#edit_tab"
    button.hover
    tooltip = find ".tooltip"
    tooltip.assert_text "Zoom in to edit the map"
  end
end
