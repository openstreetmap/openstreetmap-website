require "test_helper"

class InvalidUrlCharsValidatable
  include ActiveModel::Validations
  validates :chars, :invalid_url_chars => true
  attr_accessor :chars
end

class InvalidUrlCharsValidatorTest < ActiveSupport::TestCase
  include Rails::Dom::Testing::Assertions::SelectorAssertions

  def test_with_valid_url_chars
    c = InvalidUrlCharsValidatable.new

    valid = ["\x7f<hr>", "test@examplecom\x0e-", "s\x1ff", "aa\ufffe",
             "aa\x0b-", "aa\x08", "\uffff::", "\x00-も対応します", "\x0c*ping",
             "foo\x1fbar", "foo\x7fbar", "foo\ufffebar", "foo\uffffbar"]

    valid.each do |v|
      c.chars = v
      assert c.valid?, "'#{v}' should be valid"
    end
  end

  def test_with_invalid_url_chars
    c = InvalidUrlCharsValidatable.new

    invalid = ["Name.", "you;me", "he\"#", "<hr/>", "50%", "good?",
               "vergrößern,deutsche", "ルシステムに;.も対応します", "輕觸搖/晃的遊戲", "/;.,?%#"]

    invalid.each do |v|
      c.chars = v
      assert_not c.valid?, "'#{v}' should not be valid"
    end
  end
end
