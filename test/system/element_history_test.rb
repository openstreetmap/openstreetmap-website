require "application_system_test_case"

class ElementHistoryTest < ApplicationSystemTestCase
  test "can view node history pages" do
    node = create(:node, :with_history, :version => 41)

    visit node_path(node)

    check_element_history_pages(->(v) { old_node_path(node, v) })
  end

  test "can view way history pages" do
    way = create(:way, :with_history, :version => 41)

    visit way_path(way)

    check_element_history_pages(->(v) { old_way_path(way, v) })
  end

  test "can view relation history pages" do
    relation = create(:relation, :with_history, :version => 41)

    visit relation_path(relation)

    check_element_history_pages(->(v) { old_relation_path(relation, v) })
  end

  private

  def check_element_history_pages(get_path)
    within_sidebar do
      click_on "View History"

      41.downto(22) do |v|
        assert_link v.to_s, :href => get_path.call(v)
      end

      click_on "Older Versions"

      41.downto(2) do |v|
        assert_link v.to_s, :href => get_path.call(v)
      end

      click_on "Older Versions"

      41.downto(1) do |v|
        assert_link v.to_s, :href => get_path.call(v)
      end

      assert_no_link "Older Versions"
    end
  end
end
