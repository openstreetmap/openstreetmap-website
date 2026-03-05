# frozen_string_literal: true

require "application_system_test_case"

class GermanEmbedTest < ApplicationSystemTestCase
  driven_by_selenium(
    "de",
    :preferences => {
      "intl.accept_languages" => "de"
    }
  )

  test "shows localized report link" do
    visit export_embed_path
    assert_link "Ein Problem melden"
  end
end
