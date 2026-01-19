# frozen_string_literal: true

require "application_system_test_case"

class EmbedTest < ApplicationSystemTestCase
  test "shows localized report link" do
    visit export_embed_path
    assert_link "Report a problem"
  end
end

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
