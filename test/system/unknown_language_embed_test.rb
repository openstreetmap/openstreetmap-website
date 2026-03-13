# frozen_string_literal: true

require "application_system_test_case"

class UnknownLanguageEmbedTest < ApplicationSystemTestCase
  js_test "shows report link in fallback language", :driver => "nolang", :preferences => { "intl.accept_languages" => "unknown-language" } do
    visit export_embed_path
    assert_link "Report a problem"
  end
end
