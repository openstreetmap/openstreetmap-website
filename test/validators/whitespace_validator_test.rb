require "test_helper"

class LeadingWhitespaceValidatable
  include ActiveModel::Validations
  validates :string, :whitespace => { :leading => false }
  attr_accessor :string
end

class TrailingWhitespaceValidatable
  include ActiveModel::Validations
  validates :string, :whitespace => { :trailing => false }
  attr_accessor :string
end

class WhitespaceValidatorTest < ActiveSupport::TestCase
  include Rails::Dom::Testing::Assertions::SelectorAssertions

  def test_with_leading_whitespace
    validator = LeadingWhitespaceValidatable.new

    strings = [" ", " test", "  ", "\ttest"]

    strings.each do |v|
      validator.string = v
      assert_not validator.valid?, "'#{v}' should not be valid"
    end
  end

  def test_without_leading_whitespace
    validator = LeadingWhitespaceValidatable.new

    strings = ["test", "test ", "t est", "test\t", ".test", "_test"]

    strings.each do |v|
      validator.string = v
      assert validator.valid?, "'#{v}' should be valid"
    end
  end

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
