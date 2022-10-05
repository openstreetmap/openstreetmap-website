require "application_system_test_case"

class IndexTest < ApplicationSystemTestCase
  test "node included in edit link" do
    node = create(:node)
    visit node_path(node)
    assert_selector "#editanchor[href*='?node=#{node.id}#']"

    find("#sidebar .btn-close").click
    assert_no_selector "#editanchor[href*='?node=#{node.id}#']"
  end

  test "note included in edit link" do
    note = create(:note_with_comments)
    visit browse_note_path(note)
    assert_selector "#editanchor[href*='?note=#{note.id}#']"

    find("#sidebar .btn-close").click
    assert_no_selector "#editanchor[href*='?note=#{note.id}#']"
  end
end
