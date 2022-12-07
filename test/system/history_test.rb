require "application_system_test_case"

class HistoryTest < ApplicationSystemTestCase
  PAGE_SIZE = 20

  test "atom link on user's history is not modified" do
    user = create(:user)
    create(:changeset, :user => user, :num_changes => 1) do |changeset|
      create(:changeset_tag, :changeset => changeset, :k => "comment", :v => "first-changeset-in-history")
    end

    visit "#{user_path(user)}/history"
    changesets = find "div.changesets"
    changesets.assert_text "first-changeset-in-history"

    assert_css "link[type='application/atom+xml'][href$='#{user_path(user)}/history/feed']", :visible => false
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

  test "limit user's changesets with max_id" do
    user = create(:user)
    changeset1 = create_visible_changeset(user, "first-changeset-in-history")
    changeset2 = create_visible_changeset(user, "last-changeset-in-history")

    visit "#{user_path(user)}/history"
    find "div.changesets" do |changesets|
      changesets.assert_text "first-changeset-in-history"
      changesets.assert_text "last-changeset-in-history"
    end

    visit "#{user_path(user)}/history/#{changeset2.id}"
    find "div.changesets" do |changesets|
      changesets.assert_text "first-changeset-in-history"
      changesets.assert_text "last-changeset-in-history"
    end

    visit "#{user_path(user)}/history/#{changeset1.id}"
    find "div.changesets" do |changesets|
      changesets.assert_text "first-changeset-in-history"
      changesets.assert_no_text "last-changeset-in-history"
    end
  end

  test "update sidebar when max_id is included and map is moved" do
    changeset1 = create(:changeset, :num_changes => 1, :min_lat => 50000000, :max_lat => 50000001, :min_lon => 50000000, :max_lon => 50000001)
    create(:changeset_tag, :changeset => changeset1, :k => "comment", :v => "changeset-at-fives")
    changeset2 = create(:changeset, :num_changes => 1, :min_lat => 50100000, :max_lat => 50100001, :min_lon => 50100000, :max_lon => 50100001)
    create(:changeset_tag, :changeset => changeset2, :k => "comment", :v => "changeset-close-to-fives")

    visit "#{history_path(changeset2.id)}#map=17/5/5"
    find "div.changesets" do |changesets|
      changesets.assert_text "changeset-at-fives"
      changesets.assert_no_text "changeset-close-to-fives"
    end

    visit "#{history_path(changeset2.id)}#map=10/5/5"
    find "div.changesets" do |changesets|
      changesets.assert_text "changeset-at-fives"
      changesets.assert_text "changeset-close-to-fives"
    end

    assert_current_path history_path
  end

  def create_visible_changeset(user, comment)
    create(:changeset, :user => user, :num_changes => 1) do |changeset|
      create(:changeset_tag, :changeset => changeset, :k => "comment", :v => comment)
    end
  end
end
