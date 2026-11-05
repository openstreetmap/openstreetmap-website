# frozen_string_literal: true

require "test_helper"

class DeliverableEmailValidatorTest < ActiveSupport::TestCase
  class Validatable
    include ActiveModel::Validations

    validates :email, :deliverable_email => true
    attr_accessor :email
  end

  def test_valid
    v = Validatable.new

    valid = ["a@example.com", "a.b@example.com", "a/b@example.com", "a|b@example.com",
             "a/.b@example.com", "a+b@example.com"]

    valid.each do |email|
      v.email = email
      assert_predicate v, :valid?, "'#{email}' should be valid"
    end
  end

  def test_invalid_format
    v = Validatable.new

    invalid = ["a", "a@", "@example.com", "a@.example.com", "a..b@example.com", "a@b@example.com",
               ".ab@example.com", "a/../b@example.com", "\x00a@example.com"]

    invalid.each do |email|
      v.email = email
      assert_not_predicate v, :valid?, "'#{email}' should not be valid"
      assert_equal ["does not appear to be a valid email address"], v.errors[:email]
    end
  end

  def test_invalid_for_exim
    v = Validatable.new

    invalid = ["/ab@example.com", "|ab@example.com", "\"a@b\"@example.com",
               "a%b@example.com", "a!b@example.com"]

    invalid.each do |email|
      v.email = email
      assert_nil ValidatesEmailFormatOf.validate_email_format(email), "'#{email}' should be RFC-compliant"
      assert_not_predicate v, :valid?, "'#{email}' should not be valid"
    end
  end

  def test_restricted_characters_message
    v = Validatable.new
    v.email = "a%b@example.com"

    assert_not_predicate v, :valid?
    assert_equal ["contains invalid characters (@%!)"], v.errors[:email]
  end

  def test_restricted_local_part_message
    v = Validatable.new
    v.email = "|ab@example.com"

    assert_not_predicate v, :valid?
    assert_equal ["contains invalid characters"], v.errors[:email]
  end
end
