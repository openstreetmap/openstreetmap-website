# frozen_string_literal: true

require "application_system_test_case"

class SidebarLifecycleTest < ApplicationSystemTestCase
  test "closing a pending export allows history to load and close" do
    visit root_path
    hold_responses("/export")
    navigate_to("/export")
    assert_held_response
    navigate_to("/")
    navigate_to("/history")
    assert_selector "#sidebar_content .changesets"
    release_response
    assert_selector "#sidebar_content .changesets"
    assert_no_selector ".export_form"
    find("#sidebar .btn-close").click
    assert_selector "#content.overlay-sidebar"
    assert_no_browser_errors
  end

  test "a second activation of export survives the first response arriving last" do
    visit root_path
    hold_responses("/export")
    navigate_to("/export")
    assert_held_response
    navigate_to("/directions")
    assert_selector ".directions_form", :visible => true
    navigate_to("/export")
    assert_selector ".export_form"
    release_response
    assert_selector ".export_form"
    find_by_id("drag_box").click
    assert_no_browser_errors
  end

  test "export cannot replace directions with an endpoint placed before loading finishes" do
    visit root_path
    hold_responses("/export")
    navigate_to("/export")
    assert_held_response
    hold_responses("/directions", "directions")
    # The map context menu sets an endpoint by navigating with a from parameter.
    navigate_to("/directions?from=60,30")
    assert_held_response("directions")
    assert_selector ".directions_form", :visible => true
    assert_selector "#map .leaflet-marker-icon", :count => 1
    release_response
    release_response("directions")
    assert_selector "#directions_route", :visible => :all
    assert_no_selector ".export_form"
    assert_selector "#map .leaflet-marker-icon", :count => 1
    navigate_to("/export")
    assert_selector ".export_form"
    assert_no_selector "#map .leaflet-marker-icon"
    assert_no_browser_errors
  end

  test "leaving a pending new note does not leave its marker" do
    visit root_path
    hold_responses("/note/new")
    navigate_to("/note/new")
    assert_held_response
    navigate_to("/export")
    assert_selector ".export_form"
    release_response
    assert_no_selector "#map .leaflet-marker-icon"
    assert_selector ".export_form"
    assert_no_browser_errors
  end

  test "leaving pending element details does not select the element" do
    node = create(:node)
    visit root_path
    hold_responses(node_path(node))
    navigate_to(node_path(node))
    assert_held_response
    navigate_to("/export")
    assert_selector ".export_form"
    release_response
    assert_no_selector "#editanchor[href*='?node=']"
    assert_no_selector "#map .leaflet-marker-icon"
    assert_no_browser_errors
  end

  test "leaving pending note details does not select the note" do
    note = create(:note_with_comments)
    visit root_path
    hold_responses(note_path(note))
    navigate_to(note_path(note))
    assert_held_response
    navigate_to("/export")
    assert_selector ".export_form"
    release_response
    assert_no_selector "#editanchor[href*='?note=']"
    assert_no_selector "#map .leaflet-marker-icon"
    assert_no_browser_errors
  end

  test "note subscription finishes without restoring its sidebar" do
    note = create(:note_with_comments)
    user = create(:user)
    sign_in_as(user)
    visit note_path(note)
    hold_responses(api_note_subscription_path(note))
    click_on "Subscribe"
    assert_held_response
    navigate_to("/export")
    assert_selector ".export_form"
    release_response
    assert_selector ".export_form"
    assert NoteSubscription.exists?(:note => note, :user => user)
    assert_no_browser_errors
  end

  test "changeset subscription finishes without restoring its sidebar" do
    changeset = create(:changeset, :closed)
    user = create(:user)
    sign_in_as(user)
    visit changeset_path(changeset)
    hold_responses(api_changeset_subscription_path(changeset))
    click_on "Subscribe"
    assert_held_response
    navigate_to("/export")
    assert_selector ".export_form"
    release_response
    assert_selector ".export_form"
    assert ChangesetSubscription.exists?(:changeset => changeset, :subscriber => user)
    assert_no_browser_errors
  end

  test "history keeps the latest viewport when the previous list arrives last" do
    old_changeset = create(:changeset, :num_changes => 1, :bbox => [0.999, 0.999, 1.001, 1.001])
    new_changeset = create(:changeset, :num_changes => 1, :bbox => [19.999, 19.999, 20.001, 20.001])
    visit root_path(:anchor => "map=15/1/1")
    hold_responses("/history", "response", "list")
    navigate_to("/history")
    assert_held_response
    execute_script "sidebarTest.map.setView([20, 20], 15, {animate: false})"
    assert_selector "#changeset_#{new_changeset.id}"
    assert_no_selector "#changeset_#{old_changeset.id}"
    release_response
    assert_selector "#changeset_#{new_changeset.id}"
    assert_no_selector "#changeset_#{old_changeset.id}"
    assert_no_browser_errors
  end

  test "a late route result cannot restore directions after leaving twice" do
    visit directions_path
    hold_responses("/unused")
    execute_script <<~JS
      for (const engine of OSM.directionsEngines) {
        engine.getRoute = points => new Promise(resolve => {
          sidebarTest.held.route = () => resolve({
            line: points, steps: [], distance: 100, time: 10
          });
        });
      }
    JS
    2.times do
      navigate_to("/directions?route=60,30;61,31")
      assert_held_response("route")
      navigate_to("/export")
      assert_selector ".export_form"
      release_response("route")
      assert_no_selector "#map .leaflet-marker-icon"
      assert_no_selector "#map path[stroke='#03f']"
      assert_selector ".export_form"
    end
    assert_no_browser_errors
  end

  test "a late Overpass response cannot update the next sidebar" do
    visit root_path
    hold_responses("/unused")
    execute_script <<~JS
      const originalFetch = window.fetch;
      let count = 0;
      window.fetch = function(input, options) {
        if (input !== OSM.OVERPASS_URL) return originalFetch.call(window, input, options);
        return new Promise(resolve => {
          sidebarTest.held["query" + count++] = () => resolve(new Response(JSON.stringify({
            elements: [{type: "node", id: 123, lat: 1, lon: 1, tags: {name: "Stale query"}}]
          })));
        });
      };
    JS
    navigate_to("/query?lat=1&lon=1")
    assert_held_response("query0")
    assert_held_response("query1")
    navigate_to("/export")
    assert_selector ".export_form"
    release_response("query0")
    release_response("query1")
    assert_no_text "Stale query"
    assert_selector ".export_form"
    assert_no_browser_errors
  end

  test "a real sidebar HTTP error is reported and does not block navigation" do
    visit root_path
    hold_responses("/unused")
    execute_script <<~JS
      const originalFetch = window.fetch;
      window.fetch = function(input, options) {
        const url = new URL(input.url || input, location.href);
        if (url.pathname !== "/export") return originalFetch.call(window, input, options);
        return Promise.resolve(new Response('<turbo-frame id="sidebar_content_frame">Failed</turbo-frame>', {
          status: 500, headers: {"Content-Type": "text/html"}
        }));
      };
    JS
    navigate_to("/export")
    assert_text "Failed"
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.01 until evaluate_script("sidebarTest.errors.some(error => error.includes('HTTP Error 500'))")
    end
    navigate_to("/history")
    assert_selector "#sidebar_content .changesets"
    assert evaluate_script("sidebarTest.errors.some(error => error.includes('HTTP Error 500'))")
  end

  test "a late search result cannot replace a newer result or move the map" do
    visit root_path
    hold_responses("/unused")
    execute_script <<~JS
      const originalFetch = window.fetch;
      window.fetch = function(input, options) {
        const url = new URL(input.url || input, location.href);
        if (url.pathname !== "/search/nominatim_query") return originalFetch.call(window, input, options);
        const query = url.searchParams.get("query");
        const coordinate = query === "older" ? 1 : 20;
        const html = `<ul><li><a class="set_position" data-lat="${coordinate}" data-lon="${coordinate}" data-zoom="15">${query}</a></li></ul>`;
        if (query === "older") {
          return new Promise(resolve => sidebarTest.held.search = () => resolve(new Response(html)));
        }
        return Promise.resolve(new Response(html));
      };
    JS
    navigate_to("/search?query=older")
    assert_held_response("search")
    navigate_to("/search?query=newer")
    assert_text "newer"
    assert_selector "#map .leaflet-marker-icon", :count => 1
    position = evaluate_script("sidebarTest.map.getCenter()")
    release_response("search")
    assert_text "newer"
    assert_no_text "older"
    assert_selector "#map .leaflet-marker-icon", :count => 1
    assert_equal position, evaluate_script("sidebarTest.map.getCenter()")
    assert_no_browser_errors
  end

  test "element geometry cannot be added after its sidebar was closed" do
    node = create(:node)
    visit root_path
    hold_responses("/api/0.6/node/#{node.id}")
    navigate_to(node_path(node))
    assert_held_response
    navigate_to("/export")
    assert_selector ".export_form"
    release_response
    assert_no_selector "#editanchor[href*='?node=']"
    assert_no_selector "#map .leaflet-marker-icon"
    assert_no_browser_errors
  end

  test "pending changeset details cannot add a bounding box after leaving" do
    changeset = create(:changeset, :bbox => [1, 1, 2, 2])
    visit root_path
    hold_responses(changeset_path(changeset))
    navigate_to(changeset_path(changeset))
    assert_held_response
    navigate_to("/export")
    assert_selector ".export_form"
    release_response
    assert_no_selector "#map path[stroke='#FF9500']"
    assert_selector ".export_form"
    assert_no_browser_errors
  end

  test "a pending controller import does not block the next navigation" do
    visit root_path
    hold_responses("/unused")
    execute_script <<~JS
      const source = `
        await new Promise(resolve => window.sidebarTest.held.module = resolve);
        export default function() {
          window.sidebarTest.staleControllerCreated = true;
          return {};
        }
      `;
      OSM.MODULE_PATHS.index_export = URL.createObjectURL(new Blob([source], {type: "text/javascript"}));
    JS
    navigate_to("/export")
    assert_held_response("module")
    navigate_to("/history")
    assert_selector "#sidebar_content .changesets"
    release_response("module")
    assert_not evaluate_script("Boolean(sidebarTest.staleControllerCreated)")
    assert_no_browser_errors
  end

  test "navigation during response body reading does not leak an abort error" do
    visit root_path
    hold_responses("/unused")
    execute_script <<~JS
      const originalFetch = window.fetch;
      window.fetch = function(input, options) {
        const url = new URL(input.url || input, location.href);
        if (url.pathname !== "/export") return originalFetch.call(window, input, options);
        const html = '<turbo-frame id="sidebar_content_frame">Old export</turbo-frame>';
        const response = new Response(html, {headers: {"Content-Type": "text/html"}});
        const clone = response.clone.bind(response);
        response.clone = () => {
          const copy = clone();
          copy.text = () => new Promise((resolve, reject) => {
            sidebarTest.held.body = () => resolve(html);
            options.signal.addEventListener("abort", () => {
              reject(new DOMException("Response body interrupted", "AbortError"));
            }, {once: true});
          });
          return copy;
        };
        return Promise.resolve(response);
      };
    JS
    navigate_to("/export")
    assert_held_response("body")
    navigate_to("/history")
    assert_selector "#sidebar_content .changesets"
    release_response("body")
    assert_no_text "Old export"
    assert_selector "#sidebar_content .changesets"
    assert_no_browser_errors
  end

  private

  # Buffer a real response before holding it, so even aborting fetch cannot discard
  # it. This exercises callbacks already queued when the navigation was cancelled.
  def hold_responses(path, key = "response", query_parameter = nil)
    execute_script <<~JS, path, key, query_parameter
      const [path, key, queryParameter] = arguments;
      window.sidebarTest ??= { held: {}, errors: [] };
      if (!sidebarTest.installed) {
        sidebarTest.installed = true;
        const setSidebarOverlaid = L.OSM.Map.prototype.setSidebarOverlaid;
        L.OSM.Map.prototype.setSidebarOverlaid = function() {
          sidebarTest.map = this;
          return setSidebarOverlaid.apply(this, arguments);
        };
        addEventListener("unhandledrejection", e => sidebarTest.errors.push(String(e.reason) + " | " + (e.reason?.stack || "")));
        addEventListener("error", e => sidebarTest.errors.push(e.message + " | " + (e.error?.stack || "")));
      }
      const originalFetch = window.fetch;
      let pending = true;
      window.fetch = async function(input, options) {
        const url = new URL(input.url || input, location.href);
        const response = await originalFetch.call(window, input, options);
        if (!pending || url.pathname !== path || (queryParameter && !url.searchParams.has(queryParameter))) return response;
        pending = false;
        const body = await response.arrayBuffer();
        const buffered = new Response(response.status === 204 ? null : body, {status: response.status, headers: response.headers});
        Object.defineProperty(buffered, "url", {value: response.url});
        await new Promise(resolve => sidebarTest.held[key] = resolve);
        return buffered;
      };
    JS
  end

  def navigate_to(path)
    execute_script "OSM.router.route(arguments[0])", path
  end

  def assert_held_response(key = "response")
    assert_selector "body"
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.01 until evaluate_script("Boolean(window.sidebarTest.held[arguments[0]])", key)
    end
  end

  def release_response(key = "response")
    page.driver.browser.execute_async_script <<~JS, key
      const [key, done] = arguments;
      sidebarTest.held[key]();
      delete sidebarTest.held[key];
      // Turbo schedules rendering across animation frames.
      let frames = 0;
      function tick() {
        if (++frames === 6) done();
        else requestAnimationFrame(tick);
      }
      requestAnimationFrame(tick);
    JS
  end

  def assert_no_browser_errors
    assert_empty evaluate_script("sidebarTest.errors")
  end
end
