require "application_system_test_case"

class EmbedTest < ApplicationSystemTestCase
  test "shows localized report link" do
    visit export_embed_path
    assert_link "Report a problem"
  end
end

class GermanEmbedTest < ApplicationSystemTestCase
  driven_by :selenium, :using => :headless_firefox, :options => { :name => :selenium_de } do |options|
    options.add_preference("intl.accept_languages", "de")
  end

  test "shows localized report link" do
    visit export_embed_path
    assert_link "Ein Problem melden"
  end
end

class UnknownLanguageEmbedTest < ApplicationSystemTestCase
  driven_by :selenium, :using => :headless_firefox, :options => { :name => :selenium_unknown_language } do |options|
    options.add_preference("intl.accept_languages", "unknown-language")
  end

  test "shows report link in fallback language" do
    visit export_embed_path
    assert_link "Report a problem"
  end
end
