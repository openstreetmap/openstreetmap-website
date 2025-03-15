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

    assert_nothing_raised do
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
  end

  test "user history starts with max_id" do
    changeset0 = create(:changeset)
    user = create(:user)
    changeset1 = create_visible_changeset(user, "1st-changeset-in-history")
    changeset2 = create_visible_changeset(user, "2nd-changeset-in-history")

    visit "#{user_path user}/history?max_id=#{changeset0.id}"

    within_sidebar do
      assert_no_link "1st-changeset-in-history"
      assert_no_link "2nd-changeset-in-history"
    end

    visit "#{user_path user}/history?max_id=#{changeset1.id}"

    within_sidebar do
      assert_link "1st-changeset-in-history"
      assert_no_link "2nd-changeset-in-history"
    end

    visit "#{user_path user}/history?max_id=#{changeset2.id}"

    within_sidebar do
      assert_link "1st-changeset-in-history"
      assert_link "2nd-changeset-in-history"
    end
  end

  private

  def create_visible_changeset(user, comment)
    create(:changeset, :user => user, :num_changes => 1) do |changeset|
      create(:changeset_tag, :changeset => changeset, :k => "comment", :v => comment)
    end
  end
end
