require "test_helper"

class LanguageTest < ActiveSupport::TestCase
  fixtures :languages

  test "language count" do
    assert_equal 3, Language.count
  end
end
