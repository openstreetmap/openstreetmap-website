# frozen_string_literal: true

require "application_system_test_case"

class EmbedTest < ApplicationSystemTestCase
  test "shows localized report link" do
    visit export_embed_path
    assert_link "Report a problem"
  end
end
