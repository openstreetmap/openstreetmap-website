# frozen_string_literal: true

require "application_system_test_case"

class UnknownLanguageEmbedTest < ApplicationSystemTestCase
  driven_by_selenium(
    "nolang",
    :preferences => {
      "intl.accept_languages" => "unknown-language"
    }
  )

  test "shows report link in fallback language" do
    visit export_embed_path
    assert_link "Report a problem"
  end
end
