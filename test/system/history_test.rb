require "application_system_test_case"

class HistoryTest < ApplicationSystemTestCase
  PAGE_SIZE = 20

  test "atom link on user's history is not modified" do
    user = create(:user)
    create_visible_changeset(user, "first-changeset-in-history")

    visit "#{user_path(user)}/history"
    changesets = find "div.changesets"
    changesets.assert_text "first-changeset-in-history"

    assert_css "link[type='application/atom+xml'][href$='#{user_path(user)}/history/feed']", :visible => false
  end

  test "restore state of user's changesets list" do
    user = create(:user)
    create_visible_changeset(user, "first-changeset-in-history")
    PAGE_SIZE.times do
      create_visible_changeset(user, "next-changeset")
    end

    visit "#{user_path(user)}/history"
    original_changesets = find "div.changesets"
    original_changesets.assert_no_text "first-changeset-in-history"
    load_more = original_changesets.find ".changeset_more a.btn"
    load_more.click
    original_changesets.assert_text "first-changeset-in-history"

    visit user_path(user)
    go_back
    reloaded_changesets = find "div.changesets"
    reloaded_changesets.assert_text "first-changeset-in-history"
  end

  test "reloading the changesets page updates the list" do
    user = create(:user)
    create_visible_changeset(user, "first-changeset-in-history")
    visit "#{user_path(user)}/history"
    original_changesets = find "div.changesets"
    original_changesets.assert_text "first-changeset-in-history"
    original_changesets.assert_no_text "second-changeset-in-history"

    create_visible_changeset(user, "second-changeset-in-history")
    visit user_path(user)
    go_back
    original_changesets.assert_text "first-changeset-in-history"
    original_changesets.assert_no_text "second-changeset-in-history"

    refresh
    original_changesets.assert_text "first-changeset-in-history"
    original_changesets.assert_text "second-changeset-in-history"
  end

  test "have only one list element on user's changesets page" do
    user = create(:user)
    create_visible_changeset(user, "first-changeset-in-history")
    create_visible_changeset(user, "bottom-changeset-in-batch-2")
    (PAGE_SIZE - 1).times do
      create_visible_changeset(user, "next-changeset")
    end
    create_visible_changeset(user, "bottom-changeset-in-batch-1")
    (PAGE_SIZE - 1).times do
      create_visible_changeset(user, "next-changeset")
    end

    visit "#{user_path(user)}/history"
    changesets = find "div.changesets"
    changesets.assert_text "bottom-changeset-in-batch-1"
    changesets.assert_no_text "bottom-changeset-in-batch-2"
    changesets.assert_no_text "first-changeset-in-history"
    changesets.assert_selector "ol", :count => 1
    changesets.assert_selector "li", :count => PAGE_SIZE

    changesets.find(".changeset_more a.btn").click
    changesets.assert_text "bottom-changeset-in-batch-1"
    changesets.assert_text "bottom-changeset-in-batch-2"
    changesets.assert_no_text "first-changeset-in-history"
    changesets.assert_selector "ol", :count => 1
    changesets.assert_selector "li", :count => 2 * PAGE_SIZE

    changesets.find(".changeset_more a.btn").click
    changesets.assert_text "bottom-changeset-in-batch-1"
    changesets.assert_text "bottom-changeset-in-batch-2"
    changesets.assert_text "first-changeset-in-history"
    changesets.assert_selector "ol", :count => 1
    changesets.assert_selector "li", :count => (2 * PAGE_SIZE) + 1
  end

  test "changesets list sidebar reappears when going back after closing it" do
    user = create(:user)
    create_visible_changeset(user, "first-changeset-in-history")

    visit "#{user_path(user)}/history"
    assert_text "first-changeset-in-history"

    find("#sidebar .btn-close").click
    assert_no_text "first-changeset-in-history"

    go_back
    assert_text "first-changeset-in-history"
  end

  test "purge cached changesets lists if locale is changed" do
    user = create(:user)
    sign_in_as(user)
    create_visible_changeset(user, "first-changeset-in-history")

    visit "#{user_path(user)}/history"
    changesets_en = find "div.changesets"
    changesets_en.assert_text "first-changeset-in-history"
    changesets_en.assert_text "Closed"
    changesets_en.assert_no_text "Fermé"

    visit edit_preferences_path
    fill_in "Preferred Languages", :with => "fr"
    click_on "Update Preferences"

    visit "#{user_path(user)}/history"
    changesets_fr = find "div.changesets"
    changesets_fr.assert_text "first-changeset-in-history"
    changesets_fr.assert_no_text "Closed"
    changesets_fr.assert_text "Fermé"
  end

  test "purge cached changesets lists if schema is outdated" do
    user = create(:user)
    sign_in_as(user)
    create_visible_changeset(user, "first-changeset-in-history")
    history_path = "#{user_path(user)}/history"

    visit user_path(user)
    obsolete_data = %Q({"schema":1,"locale":"en","items":[{"key":"#{history_path}","lists":["<p>obsolete-data</p>"]}]})
    execute_script %Q(sessionStorage["history-user"]='#{obsolete_data}')

    visit history_path
    changesets = find "div.changesets"
    changesets.assert_text "first-changeset-in-history"
    changesets.assert_no_text "obsolete-data"
  end

  def create_visible_changeset(user, comment)
    create(:changeset, :closed, :user => user, :num_changes => 1) do |changeset|
      create(:changeset_tag, :changeset => changeset, :k => "comment", :v => comment)
    end
  end
end
