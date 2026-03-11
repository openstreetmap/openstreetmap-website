# frozen_string_literal: true

require "application_system_test_case"

class GermanEmbedTest < ApplicationSystemTestCase
  js_test "shows localized report link", :driver => "de", :preferences => { "intl.accept_languages" => "de" } do
    visit export_embed_path
    assert_link "Ein Problem melden"
  end
end
