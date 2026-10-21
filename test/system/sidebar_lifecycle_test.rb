# frozen_string_literal: true

require "application_system_test_case"

class SidebarLifecycleTest < ApplicationSystemTestCase
  test "a second sidebar content load survives the first response arriving last" do
    visit root_path
    hold_responses("/export")
    load_sidebar("/export")
    assert_held_response
    load_sidebar("/history")
    assert_selector "#sidebar_content .changesets"
    load_sidebar("/export")
    assert_selector ".export_form"
    release_response
    assert_selector ".export_form"
    assert_no_browser_errors
  end

  test "superseding a load during response body reading does not leak an abort error" do
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
    load_sidebar("/export")
    assert_held_response("body")
    load_sidebar("/history")
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

  def load_sidebar(path)
    execute_script <<~JS, path
      OSM.loadSidebarContent(arguments[0]).catch(error => {
        if (error.name !== "AbortError") reportError(error);
      });
    JS
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
