# frozen_string_literal: true

require "application_system_test_case"

class DirectionsSystemTest < ApplicationSystemTestCase
  test "updates route output on mode change" do
    visit directions_path
    stub_straight_routing(:start_instruction => "Start popup text")

    find_by_id("route_from").set("60 30").send_keys :enter
    find_by_id("route_to").set("61 31").send_keys :enter

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
    stub_straight_routing(:start_instruction => "Start popup text")

    find_by_id("route_from").set("60 30").send_keys :enter
    find_by_id("route_to").set("61 31").send_keys :enter

    click_on :class => "reverse_directions"

    start_location = find_by_id("route_from").value
    finish_location = find_by_id("route_to").value

    click_on :class => "reverse_directions"

    assert_equal finish_location, find_by_id("route_from").value
    assert_equal start_location, find_by_id("route_to").value
  end

  test "removes popup on sidebar close" do
    visit directions_path
    stub_straight_routing(:start_instruction => "Start popup text")

    find_by_id("route_from").set("60 30").send_keys :enter
    find_by_id("route_to").set("61 31").send_keys :enter

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
  test "selects from datalist and shows route" do
    visit directions_path
    stub_nominatim_search
    stub_straight_routing(:start_instruction => "Head north")

    find_by_id("route_from").set("Berlin").send_keys :enter

    find_by_id("route_from").set("Berlin, Germany").send_keys :enter

    assert_equal "52.52", find_by_id("route_from")["data-lat"]
    assert_equal "13.405", find_by_id("route_from")["data-lon"]

    find_by_id("route_to").set("Venice").send_keys :enter
    find_by_id("route_to").set("Venice, Veneto, Italy").send_keys :enter

    assert_equal "45.4408", find_by_id("route_to")["data-lat"]
    assert_equal "12.3155", find_by_id("route_to")["data-lon"]

    within "#sidebar" do
      assert_content "Head north"
    end
  end

  private

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
        for (const engine of OSM.Directions.engines) {
          engine.getRoute = function(points, signal) {
              #{callback_code}
          };
        }
      });
    SCRIPT
  end
end

def stub_nominatim_search
  execute_script <<~SCRIPT
    {
      const originalFetch = fetch;
      window.fetch = (...args) => {
        const [resource, options] = args;

        if (!resource.includes(OSM.NOMINATIM_URL + "search")) {
          return originalFetch(...args);
        }

        const results = [
          { "display_name": "Berlin, Germany", "lat": "52.5200", "lon": "13.4050" },
          { "display_name": "Venice, Veneto, Italy", "lat": "45.4408", "lon": "12.3155" }
        ];

        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve(results)
        });
      }
    }
  SCRIPT
end
