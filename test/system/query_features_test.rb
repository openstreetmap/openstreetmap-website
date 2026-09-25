# frozen_string_literal: true

require "application_system_test_case"

class QueryFeaturesSystemTest < ApplicationSystemTestCase
  test "sorts enclosing features correctly" do
    visit "/#map=15/54.18315/7.88473"

    within "#map" do
      click_on "Query features"

      stub_overpass :enclosing_elements => [
        {
          "type" => "relation",
          "id" => 51477,
          "bounds" => {
            "minlat" => 47.2701114,
            "minlon" => 5.8663153,
            "maxlat" => 55.0991610,
            "maxlon" => 15.0419309
          },
          "tags" => {
            "admin_level" => "2",
            "border_type" => "country",
            "boundary" => "administrative",
            "name" => "Deutschland",
            "name:de" => "Deutschland",
            "name:en" => "Germany",
            "type" => "boundary"
          }
        },
        {
          "type" => "relation",
          "id" => 51529,
          "bounds" => {
            "minlat" => 53.3598160,
            "minlon" => 7.5211615,
            "maxlat" => 55.0991610,
            "maxlon" => 11.6723860
          },
          "tags" => {
            "admin_level" => "4",
            "border_type" => "state",
            "boundary" => "administrative",
            "name" => "Schleswig-Holstein",
            "name:de" => "Schleswig-Holstein",
            "name:en" => "Schleswig-Holstein",
            "type" => "boundary"
          }
        },
        {
          "type" => "relation",
          "id" => 3787052,
          "bounds" => {
            "minlat" => 54.1693099,
            "minlon" => 7.8648436,
            "maxlat" => 54.1907839,
            "maxlon" => 7.9001626
          },
          "tags" => {
            "name" => "Helgoland",
            "name:de" => "Helgoland",
            "name:en" => "Heligoland",
            "place" => "island"
          }
        }
      ]

      click
    end

    within_sidebar do
      assert_link "Heligoland"
      assert_link "Schleswig-Holstein", :below => find_link("Heligoland")
      assert_link "Germany", :below => find_link("Schleswig-Holstein")
    end
  end

  test "sorts enclosing features correctly across antimeridian" do
    visit "/#map=15/60/30"

    within "#map" do
      click_on "Query features"

      stub_overpass :enclosing_elements => [
        {
          "type" => "relation",
          "id" => 60189,
          "bounds" => {
            "minlat" => 41.1850968,
            "minlon" => 19.4041722,
            "maxlat" => 82.0586232,
            "maxlon" => -168.9769440
          },
          "tags" => {
            "admin_level" => "2",
            "border_type" => "nation",
            "boundary" => "administrative",
            "name" => "Россия",
            "name:en" => "Russia",
            "name:ru" => "Россия",
            "type" => "boundary"
          }
        },
        {
          "type" => "relation",
          "id" => 1114253,
          "bounds" => {
            "minlat" => 59.8587853,
            "minlon" => 29.6720697,
            "maxlat" => 60.0370554,
            "maxlon" => 30.2307057
          },
          "tags" => {
            "name" => "Невская губа",
            "name:en" => "Neva Bay",
            "name:ru" => "Невская губа",
            "natural" => "bay",
            "type" => "multipolygon"
          }
        }
      ]

      click
    end

    within_sidebar do
      assert_link "Neva Bay"
      assert_link "Russia", :below => find_link("Neva Bay")
    end
  end

  test "sorts enclosing features correctly with multiple bboxes across antimeridian" do
    visit "/#map=15/-16.155/179.995"

    within "#map" do
      click_on "Query features"

      stub_overpass :enclosing_elements => [
        {
          "type" => "relation",
          "id" => 571747,
          "bounds" => {
            "minlat" => -21.9434274,
            "minlon" => 174.4214965,
            "maxlat" => -12.2613866,
            "maxlon" => -178.0034928
          },
          "tags" => {
            "admin_level" => "2",
            "boundary" => "administrative",
            "name" => "Viti",
            "name:en" => "Fiji",
            "name:fj" => "Viti",
            "type" => "boundary"
          }
        },
        {
          "type" => "relation",
          "id" => 2325025,
          "bounds" => {
            "minlat" => -17.0160140,
            "minlon" => 178.4754914,
            "maxlat" => -16.1243512,
            "maxlon" => -179.6630100
          },
          "tags" => {
            "name" => "Vanua Levu Group",
            "place" => "archipelago",
            "type" => "multipolygon",
            "wikidata" => "Q2756586"
          }
        },
        {
          "type" => "relation",
          "id" => 4097003,
          "bounds" => {
            "minlat" => -17.0160140,
            "minlon" => 178.4754914,
            "maxlat" => -16.1243512,
            "maxlon" => -179.9513876
          },
          "tags" => {
            "name" => "Vanua Levu",
            "place" => "island",
            "type" => "multipolygon",
            "wikidata" => "Q327733"
          }
        }
      ]

      click
    end

    within_sidebar do
      assert_link "Vanua Levu"
      assert_link "Vanua Levu Group", :below => find_link("Vanua Levu")
      assert_link "Fiji", :below => find_link("Vanua Levu Group")
    end
  end

  private

  def stub_overpass(nearby_elements: [], enclosing_elements: [])
    execute_script <<~SCRIPT
      {
        const originalFetch = fetch;
        window.fetch = (...args) => {
          const [resource, options] = args;

          if (resource != OSM.OVERPASS_URL) return originalFetch(...args);

          const data = options.body.get("data"),
                elements = data.includes("is_in") ? #{enclosing_elements.to_json} : #{nearby_elements.to_json};

          return Promise.resolve({
            ok: true,
            json: () => Promise.resolve({ elements })
          });
        }
      }
    SCRIPT
  end
end
