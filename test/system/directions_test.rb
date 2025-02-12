require "application_system_test_case"

class DirectionsSystemTest < ApplicationSystemTestCase
  test "removes popup on sidebar close" do
    visit directions_path
    stub_straight_routing(:start_instruction => "Start popup text")

    fill_in "route_from", :with => "60 30"
    fill_in "route_to", :with => "61 31"
    click_on "Go"

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

    within_sidebar do
      find("button[aria-label='Close']").click
    end

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
          [points[0],  8, "<b>1.</b> #{start_instruction}", distance, points],
          [points[1], 14, "<b>2.</b> #{finish_instruction}", 0, [points[1]]]
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
          engine.getRoute = (points, signal) => {
              #{callback_code}
          };
        }
      });
    SCRIPT
  end
end
