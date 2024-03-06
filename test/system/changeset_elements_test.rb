require "application_system_test_case"

class ChangesetElementsTest < ApplicationSystemTestCase
  test "can navigate between element subpages without losing comment input" do
    element_page_size = 20
    changeset = create(:changeset, :closed)
    ways = create_list(:way, element_page_size + 1, :with_history, :changeset => changeset)
    way_paths = ways.map { |way| way_path(way) }
    nodes = create_list(:node, element_page_size + 1, :with_history, :changeset => changeset)
    node_paths = nodes.map { |node| node_path(node) }

    sign_in_as(create(:user))
    visit changeset_path(changeset)

    within_sidebar do
      assert_one_missing_link way_paths
      assert_link "Ways (21-21 of 21)"

      assert_one_missing_link node_paths
      assert_link "Nodes (21-21 of 21)"
    end
  end

  private

  def assert_one_missing_link(hrefs)
    missing_href = nil
    hrefs.each do |href|
      missing = true
      assert_link :href => href, :minimum => 0, :maximum => 1 do
        missing = false
      end
      if missing
        assert_nil missing_href, "unexpected extra missing link '#{href}'"
        missing_href = href
      end
    end
    assert_not_nil missing_href, "expected one link missing but all are present"
    missing_href
  end
end
