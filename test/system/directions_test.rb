# frozen_string_literal: true

require "application_system_test_case"

class DirectionsSystemTest < ApplicationSystemTestCase
  test "routes to a different mapped entrance" do
    visit directions_path
    stub_straight_routing(:finish_instruction => "Arrive at ${points[1].lat}, ${points[1].lng}")
    stub_entrance_search([
                           { :type => "yes", :lat => "61.1", :lon => "31", :extratags => { :ref => "West" } },
                           { :type => "main", :lat => "61.2", :lon => "31", :extratags => { :name => "North" } },
                           { :type => "main", :lat => "61.3", :lon => "31", :extratags => { :access => "private" } }
                         ])

    fill_in "route_from", :with => "60 30"
    fill_in("route_to", :with => "Museum").send_keys :tab
    assert_select "Destination entrance", :options => ["Entrance (West)", "Main entrance (North)"], :selected => "Main entrance (North)"
    assert_text "Arrive at 61.2, 31"

    select "Entrance (West)", :from => "Destination entrance"
    assert_text "Arrive at 61.1, 31"
    assert_field "route_to", :with => "Museum"

    fill_in("route_to", :with => "62 32").send_keys :tab
    assert_text "Arrive at 62, 32"
    assert_no_select "Destination entrance"
  end

  test "routes directly to the only eligible entrance or to the place when there are none" do
    visit directions_path
    stub_straight_routing(:finish_instruction => "Arrive at ${points[1].lat}, ${points[1].lng}")
    stub_entrance_search([{ :type => "yes", :lat => "61.1", :lon => "31" }])
    fill_in "route_from", :with => "60 30"
    fill_in("route_to", :with => "Museum").send_keys :tab
    assert_text "Arrive at 61.1, 31"
    assert_no_select "Destination entrance"

    stub_entrance_search(nil)
    fill_in("route_to", :with => "Another museum").send_keys :tab
    assert_text "Arrive at 61, 31"
    assert_no_select "Destination entrance"
  end

  test "updates route output on mode change" do
    visit directions_path

    fill_in "route_from", :with => "60 30"
    stub_straight_routing(:start_instruction => "Start popup text")
    fill_in("route_to", :with => "61 31").send_keys :enter

    within "#sidebar" do
      assert_content "Start popup text (car)"
    end

    choose :option => "bicycle", :allow_label_click => true

    within "#sidebar" do
      assert_content "Start popup text (bicycle)"
    end
  end

  test "swaps route endpoints on reverse button click" do
    visit directions_path

    fill_in "route_from", :with => "60 30"
    stub_straight_routing(:start_instruction => "Start popup text")
    stub_disable_reverse_geocoding
    fill_in("route_to", :with => "61 31").send_keys :enter

    click_on :class => "reverse_directions"

    start_location = find_by_id("route_from").value
    finish_location = find_by_id("route_to").value

    click_on :class => "reverse_directions"

    assert_equal finish_location, find_by_id("route_from").value
    assert_equal start_location, find_by_id("route_to").value
  end

  test "removes popup on sidebar close" do
    visit directions_path

    fill_in "route_from", :with => "60 30"
    stub_straight_routing(:start_instruction => "Start popup text")
    fill_in("route_to", :with => "61 31").send_keys :enter

    within "#map" do
      assert_no_content "Start popup text"
    end

    within_sidebar do
      direction_entry = find "td", :text => "Start popup text"
      direction_entry.click
    end

    within "#map" do
      assert_content "Start popup text"
    end

    find("#sidebar .sidebar-close-controls button[aria-label='Close']").click

    within "#map" do
      assert_no_content "Start popup text"
    end
  end

  test "shows the route again on enter after sidebar close" do
    visit directions_path

    fill_in "route_from", :with => "60 30"
    stub_straight_routing(:start_instruction => "Start popup text")
    fill_in("route_to", :with => "61 31").send_keys :enter

    within_sidebar do
      assert_content "Start popup text"
    end

    find("#sidebar .sidebar-close-controls button[aria-label='Close']").click

    assert_no_selector "#sidebar_content", :text => "Start popup text"

    find_by_id("route_to").send_keys :enter

    within_sidebar do
      assert_content "Start popup text"
    end
  end

  private

  def stub_entrance_search(entrances)
    page.execute_script(<<~JS, entrances)
      const entrances = arguments[0];
      const originalFetch = window.fetch;
      window.fetch = function(input, init) {
        const url = new URL(input.url || input, location.href);
        if (url.href.startsWith(OSM.NOMINATIM_URL + "search?") && url.searchParams.get("entrances") === "1") {
          return Promise.resolve(Response.json([{ display_name: url.searchParams.get("q"), lat: "61", lon: "31", entrances }]));
        }
        if (url.href.startsWith(OSM.NOMINATIM_URL + "reverse?")) return Promise.resolve(Response.json({}));
        return originalFetch.call(this, input, init);
      };
    JS
  end

  def stub_straight_routing(start_instruction: "Start here", finish_instruction: "Finish there")
    stub_routing <<~CALLBACK
      const distance = points[0].distanceTo(points[1]);
      const time = distance * 30;
      return Promise.resolve({
        line: points,
        steps: [
          ["start", `<b>1.</b> #{start_instruction} (${this.mode})`, distance, points],
          ["destination", `<b>2.</b> #{finish_instruction} (${this.mode})`, 0, [points[1]]]
        ],
        distance,
        time
      });
    CALLBACK
  end

  def stub_routing(callback_code)
    execute_script <<~SCRIPT
      $(() => {
        for (const engine of OSM.directionsEngines) {
          engine.getRoute = function(points, signal) {
              #{callback_code}
          };
        }
      });
    SCRIPT
  end

  def stub_disable_reverse_geocoding
    execute_script <<~SCRIPT
      $(() => {
        const originalFetch = window.fetch;
        window.fetch = function(input, init) {
          if (!input?.url?.startsWith(OSM.NOMINATIM_URL)) return originalFetch.apply(this, arguments);
          return Promise.resolve(new Response(JSON.stringify({}), {
            status: 200,
            headers: { "Content-Type": "application/json" }
          }));
        };
      });
    SCRIPT
  end
end
