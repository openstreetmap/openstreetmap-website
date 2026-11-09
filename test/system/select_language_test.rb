# frozen_string_literal: true

require "application_system_test_case"

class SelectLanguageTest < ApplicationSystemTestCase
  test "language selector loads once for the current page and resets on reopen" do
    visit help_path(:verify_source => "one two")
    page.execute_script(<<~JS)
      window.languageSelectorRequests = [];
      document.addEventListener("turbo:before-fetch-request", event => {
        if (event.target.id === "select_language_list") {
          window.languageSelectorRequests.push(new URL(event.detail.url).searchParams.get("source"));
        }
      });
      document.getElementById("select_language_dialog").addEventListener("shown.bs.modal", event => {
        const dialog = event.currentTarget;
        dialog.dataset.shownEvents = Number(dialog.dataset.shownEvents || 0) + 1;
      });
      // Simulate the frame becoming loadable before the modal finishes opening.
      document.getElementById("select_language_list").setAttribute("loading", "eager");
    JS
    page.evaluate_async_script(<<~JS)
      const done = arguments[arguments.length - 1];
      const frame = document.getElementById("select_language_list");
      if (frame.hasAttribute("src") && !frame.hasAttribute("complete")) {
        frame.addEventListener("turbo:frame-load", done, { once: true });
      } else {
        done();
      }
    JS
    page.execute_script("window.history.pushState({}, '', '?verify_source=after+navigation')")
    source = page.evaluate_script("window.location.pathname + window.location.search")

    click_on "Select Language"
    assert_selector "#select_language_dialog[data-shown-events='1'] #select_language_list[complete]"
    assert_selector "#language_search:focus"
    assert_equal [source], page.evaluate_script("window.languageSelectorRequests")

    find_by_id("language_search").set("fra")
    within("#select_language_list") { assert_no_text "English" }
    within("#select_language_dialog") { click_button "Close" }
    assert_no_selector "#select_language_dialog.show"
    click_on "Select Language"
    assert_selector "#select_language_dialog[data-shown-events='2'] #language_search:focus"
    assert_equal "", find_by_id("language_search").value
    within("#select_language_list") { assert_text "English" }
    assert_equal [source], page.evaluate_script("window.languageSelectorRequests")
  end

  test "can select language when logged out" do
    visit help_path

    within_content_heading do
      assert_text "Getting Help"
      assert_no_text "Obtenir de l’aide"
    end

    click_on "Select Language"

    assert_content "English"
    find_by_id("language_search").set("fra").send_keys(:tab)
    assert_not_includes find_by_id("select_language_list").text, "English"

    click_on "français"

    within_content_heading do
      assert_no_text "Getting Help"
      assert_text "Obtenir de l’aide"
    end
  end

  test "can select language when logged in" do
    user = create(:user, :display_name => "LanguageTestUser")
    sign_in_as(user)

    visit help_path

    assert_no_text "Préférences mises à jour"
    within_content_heading do
      assert_text "Getting Help"
      assert_no_text "Obtenir de l’aide"
    end

    click_on "Select Language"

    assert_content "English"
    find_by_id("language_search").set("fra").send_keys(:tab)
    assert_not_includes find_by_id("select_language_list").text, "English"

    click_on "français"

    assert_text "Préférences mises à jour"
    within_content_heading do
      assert_no_text "Getting Help"
      assert_text "Obtenir de l’aide"
    end

    click_on "LanguageTestUser"
    click_on "Mes préférences"

    within_content_body do
      assert_select "Langue préférée", :selected => "français"
    end
  end
end
