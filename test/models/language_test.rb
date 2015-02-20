require "test_helper"

class LanguageTest < ActiveSupport::TestCase
  test "language count" do
    assert_equal 3, Language.count
  end
end
