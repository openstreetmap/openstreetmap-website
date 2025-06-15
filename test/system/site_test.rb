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
    visit "/#layers=H" # assumes that HOT layer has no map key

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

  test "tooltips on low zoom levels for disabled control 'Edit'" do
    check_control_tooltips_on_low_zoom "Edit"
  end
  test "tooltips on low zoom levels for disabled control 'Add a note to the map'" do
    check_control_tooltips_on_low_zoom "Add a note to the map"
  end
  test "tooltips on low zoom levels for disabled control 'Query features'" do
    check_control_tooltips_on_low_zoom "Query features"
  end

  test "no zoom-in tooltips on high zoom levels, then tooltips appear after zoom out for control 'Edit'" do
    check_control_tooltips_on_high_zoom "Edit"
  end
  test "no zoom-in tooltips on high zoom levels, then tooltips appear after zoom out for control 'Add a note to the map'" do
    check_control_tooltips_on_high_zoom "Add a note to the map"
  end
  test "no zoom-in tooltips on high zoom levels, then tooltips appear after zoom out for control 'Query features'" do
    check_control_tooltips_on_high_zoom "Query features"
  end

  test "notes layer tooltip appears on zoom out" do
    visit "/#map=10/40/-4" # depends on zoom levels where notes are allowed

    within "#map" do
      click_on "Layers"
    end
    within "#map-ui" do
      assert_field "Map Notes"
      find_field("Map Notes").hover # try to trigger disabled tooltip
    end
    within "#map" do
      zoom_out = find_link("Zoom Out")
      zoom_out.hover # un-hover the tooltip that's being tested
      zoom_out.click(:shift)
    end
    within "#map-ui" do
      assert_field "Map Notes", :disabled => true
      find_field("Map Notes", :disabled => true).hover
    end
    assert_selector ".tooltip", :text => "Zoom in to see"
  end

  test "language selector should be active when logged out" do
    visit "/"

    within "#language-selector" do
      assert_selector ".dropdown-toggle[data-bs-toggle='dropdown']", :visible => "all"

      AVAILABLE_LANGUAGES.each do |locale|
        assert_selector ".dropdown-item[data-language='#{locale[:code]}']", :visible => "all"
      end

      click_on "Language Selector"
      click_on "français"
    end

    assert_selector "html[lang='fr']"
  end

  test "language selector should not be active when logged in" do
    sign_in_as(create(:user))

    visit "/"

    within "#language-selector" do
      assert_no_selector ".dropdown-toggle[data-bs-toggle='dropdown']", :visible => "all"

      click_on "Language Selector"
    end

    assert_current_path basic_preferences_path
  end

  private

  def check_control_tooltips_on_low_zoom(locator)
    visit "/#map=10/0/0"

    assert_no_selector ".tooltip"
    find_link(locator).hover
    assert_selector ".tooltip", :text => "Zoom in to"
  end

  def check_control_tooltips_on_high_zoom(locator)
    visit "/#map=14/0/0"

    assert_no_selector ".tooltip"
    find_link(locator).hover
    assert_no_selector ".tooltip", :text => "Zoom in to"
    find("h1").hover # un-hover original element

    visit "#map=10/0/0"
    find_link(locator, :class => "disabled") # Ensure that capybara has waited for JS to finish processing

    assert_no_selector ".tooltip"
    find_link(locator).hover
    assert_selector ".tooltip", :text => "Zoom in to"
  end
end
