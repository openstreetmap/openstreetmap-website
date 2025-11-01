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
