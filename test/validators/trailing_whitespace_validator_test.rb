require "test_helper"

class TrailingWhitespaceValidatable
  include ActiveModel::Validations
  validates :string, :trailing_whitespace => true
  attr_accessor :string
end

class TrailingWhitespaceValidatorTest < ActiveSupport::TestCase
  include Rails::Dom::Testing::Assertions::SelectorAssertions

  def test_with_trailing_whitespace
    validator = TrailingWhitespaceValidatable.new

    strings = [" ", "test ", "  ", "test\t", "_test_ "]

    strings.each do |v|
      validator.string = v
      assert_not validator.valid?, "'#{v}' should not be valid"
    end
  end

  def test_without_trailing_whitespace
    validator = TrailingWhitespaceValidatable.new

    strings = ["test", " test", "tes t", "\ttest", "test.", "test_"]

    strings.each do |v|
      validator.string = v
      assert validator.valid?, "'#{v}' should be valid"
    end
  end
end
