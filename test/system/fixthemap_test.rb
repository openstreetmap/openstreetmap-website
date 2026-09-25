# frozen_string_literal: true

require "application_system_test_case"

class FixthemapTest < ApplicationSystemTestCase
  test "should have 'create a note' link with correct map hash" do
    visit fixthemap_path(:lat => 60, :lon => 30, :zoom => 10)

    within_content_body do
      assert_link "Add a note to the map", :href => %r{/note/new#map=10/60(\.\d+)?/30(\.\d+)?}
    end
  end
end
