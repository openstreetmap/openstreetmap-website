require "application_system_test_case"

class HistoryTest < ApplicationSystemTestCase
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
end
