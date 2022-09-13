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

  [
    "#edit_tab",
    ".control-note .control-button",
    ".control-query .control-button"
  ].each do |selector|
    test "tooltips on low zoom levels for disabled control '#{selector}'" do
      visit "/#map=10/0/0"

      assert_no_selector ".tooltip"
      find(selector).hover
      assert_selector ".tooltip", :text => "Zoom in"
    end

    test "no zoom-in tooltips on high zoom levels, then tooltips appear after zoom out for control '#{selector}'" do
      visit "/#map=14/0/0"

      assert_no_selector ".tooltip"
      find(selector).hover
      assert_no_selector ".tooltip", :text => "Zoom in"
      find("h1").hover # un-hover original element

      visit "/#map=10/0/0"
      find(selector).hover
      assert_selector ".tooltip", :text => "Zoom in"
    end
  end

  test "notes layer tooltip appears on zoom out" do
    visit "/#map=9/40/-4" # depends on zoom levels where notes are allowed

    find(".control-layers .control-button").click
    li = find(".layers-ui .overlay-layers li:first-child")
    li.not_matches_css? ".disabled"
    li.hover # try to trigger disabled tooltip
    zoomout = find(".control-button.zoomout")
    zoomout.hover # un-hover the tooltip that's being tested
    zoomout.click
    li.matches_css? ".disabled"
    li.hover
    assert_selector ".tooltip", :text => "Zoom in"
  end
end
