# frozen_string_literal: true

require "application_system_test_case"

class SearchTest < ApplicationSystemTestCase
  def setup
    stub_request(:get, %r{^https://nominatim\.openstreetmap\.org/search\?})
      .to_return(:status => 404)

    stub_request(:get, %r{^https://nominatim\.openstreetmap\.org/reverse\?})
      .to_return(:status => 404)

    stub_request(:get, %r{^https://nominatim\.openstreetmap\.org/reverse\?.*zoom=$})
      .to_return(:status => 400, :body => <<-BODY)
        <?xml version="1.0" encoding="UTF-8"?>
        <error>
          <code>400</code>
          <message>Parameter 'zoom' must be a number.</message>
        </error>
      BODY

    stub_request(:get, %r{^https://nominatim\.openstreetmap\.org/reverse\?.*zoom=15$})
      .to_return(:status => 200, :body => <<-BODY)
        <?xml version="1.0" encoding="UTF-8"?>
        <reversegeocode timestamp="Sun, 01 Mar 15 22:49:45 +0000" attribution="Data © OpenStreetMap contributors, ODbL 1.0. http://www.openstreetmap.org/copyright" querystring="accept-language=&amp;lat=51.76320&amp;lon=-0.00760&amp;zoom=15">
          <result place_id="150696" osm_type="node" osm_id="28825933" ref="Broxbourne" lat="51.7465723" lon="-0.0190782">Broxbourne, Hertfordshire, East of England, England, United Kingdom</result>
          <addressparts>
            <suburb>Broxbourne</suburb>
            <city>Broxbourne</city>
            <county>Hertfordshire</county>
            <state_district>East of England</state_district>
            <state>England</state>
            <country>United Kingdom</country>
            <country_code>gb</country_code>
          </addressparts>
        </reversegeocode>
      BODY
  end

  test "click on 'where is this' sets search input value and makes reverse geocoding request with zoom" do
    visit "/#map=15/51.76320/-0.00760"

    assert_field "Search", :with => ""
    click_on "Where is this?"

    assert_field "Search", :with => "51.76320, -0.00760"
    assert_link "Broxbourne, Hertfordshire, East of England, England, United Kingdom"
  end

  test "'Show address' from context menu makes reverse geocoding request with zoom" do
    visit "/#map=15/51.76320/-0.00760"

    find_by_id("map").right_click
    click_on "Show address"

    assert_link "Broxbourne, Hertfordshire, East of England, England, United Kingdom"
  end

  test "search result colors stay the same whichever source responds first" do
    colors = %w[latlon_query nominatim_reverse_query].map do |delayed_source|
      visit "/#map=15/51.76320/-0.00760"
      page.execute_script(<<~JS, delayed_source)
        const delayedPath = arguments[0];
        const fetch = window.fetch.bind(window);
        const gate = new Promise(resolve => { window.releaseSearchResult = resolve; });
        window.fetch = async (...args) => {
          const response = await fetch(...args);
          if (new URL(response.url).pathname.endsWith("/" + delayedPath)) await gate;
          return response;
        };
      JS

      click_on "Where is this?"
      rows = "#sidebar_content .results-list > li"
      assert_selector "#{rows}[style*='--marker-color']", :count => 1
      first_color = find(rows).style("--marker-color").fetch("--marker-color")
      assert_selector "#map .activatable use[color='#{first_color.strip}']", :visible => :all

      page.execute_script("window.releaseSearchResult()")
      assert_selector "#{rows}[style*='--marker-color']", :count => 2
      all(rows).map { |row| row.style("--marker-color").fetch("--marker-color").strip }
    end

    assert_equal colors.first, colors.last
    assert_equal 2, colors.first.uniq.size
  end

  test "query search link sets search input value" do
    visit search_path(:query => "2.341, 7.896")

    assert_field "Search", :with => "2.341, 7.896"
  end

  test "latlon search link sets search input value" do
    visit search_path(:lat => "4.321", :lon => "9.876")

    assert_field "Search", :with => "4.321, 9.876"
  end

  test "search adds viewbox param to Nominatim link" do
    visit "/"

    fill_in "query", :with => "paris"
    click_on "Go"

    within_sidebar do
      assert_link "Nominatim", :href => /&viewbox=/
    end
  end

  test "search adds zoom param to reverse Nominatim link" do
    visit "/#map=7/1.234/6.789"

    fill_in "query", :with => "60 30"
    click_on "Go"

    within_sidebar do
      assert_link "Nominatim", :href => /&zoom=7/
    end
  end
end
