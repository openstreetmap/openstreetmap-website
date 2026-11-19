# frozen_string_literal: true

require "application_system_test_case"

class FixthemapTest < ApplicationSystemTestCase
  test "should have 'create a note' link with correct map hash" do
    visit fixthemap_path(:lat => 60, :lon => 30, :zoom => 10)

    within_content_body do
      assert_link "Add a note to the map", :href => %r{/note/new#map=10/60(\.\d+)?/30(\.\d+)?}
    end
  end

  test "should have 'start mapping' button redirecting to editor with correct map hash" do
    user = create(:user)
    sign_in_as(user)

    visit fixthemap_path(:lat => 60, :lon => 30, :zoom => 10)
    click_on "Start Mapping"
    assert_current_path edit_path
    assert_match %r{map=10/60(\.\d+)?/30(\.\d+)?}, current_url
  end
end
