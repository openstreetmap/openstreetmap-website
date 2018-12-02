require "test_helper"

class InvalidCharsValidatable
  include ActiveModel::Validations
  validates :chars, :characters => true
  attr_accessor :chars
end

class InvalidUrlCharsValidatable
  include ActiveModel::Validations
  validates :chars, :characters => { :url_safe => true }
  attr_accessor :chars
end

class CharactersValidatorTest < ActiveSupport::TestCase
  include Rails::Dom::Testing::Assertions::SelectorAssertions

  def test_with_valid_chars
    c = InvalidCharsValidatable.new

    valid = ["Name.", "'me", "he\"", "<hr>", "*ho", "\"help\"@",
             "vergrößern", "ルシステムにも対応します", "輕觸搖晃的遊戲", "/;.,?%#"]

    valid.each do |v|
      c.chars = v
      assert c.valid?, "'#{v}' should be valid"
    end
  end

  def test_with_invalid_chars
    c = InvalidCharsValidatable.new

    invalid = ["\x7f<hr/>", "test@example.com\x0e-", "s/\x1ff", "aa/\ufffe",
               "aa\x0b-,", "aa?\x08", "/;\uffff.,?", "\x00-も対応します/", "\x0c#ping",
               "foo\x1fbar", "foo\x7fbar", "foo\ufffebar", "foo\uffffbar"]

    invalid.each do |v|
      c.chars = v
      assert_not c.valid?, "'#{v}' should not be valid"
    end
  end

  def test_with_valid_url_chars
    c = InvalidUrlCharsValidatable.new

    valid = ["Name", "'me", "he\"", "<hr>", "*ho", "\"help\"@",
             "vergrößern", "ルシステムにも対応します", "輕觸搖晃的遊戲"]

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
