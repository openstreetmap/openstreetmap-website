# frozen_string_literal: true

require "test_helper"

class UserPreferenceTest < ActiveSupport::TestCase
  # Checks that you cannot add a new preference, that is a duplicate
  def test_add_duplicate_preference
    up = create(:user_preference)
    new_up = build(:user_preference)
    new_up.user = up.user
    new_up.k = up.k
    new_up.v = "some other value"
    assert_not_equal new_up.v, up.v
    assert_raise(ActiveRecord::RecordNotUnique) { new_up.save }
  end

  def test_key_length_valid
    up = build(:user_preference)
    up.user = create(:user)
    up.k = "k" * 255
    up.v = "v"
    assert_predicate up, :valid?
    assert up.save!
    resp = UserPreference.find(up.id)
    assert_equal "k" * 255, resp.k, "User preference with 255 k chars fails"
    assert_equal "v", resp.v
  end

  def test_key_length_invalid
    up = build(:user_preference)
    up.user = create(:user)
    up.k = "k" * 256
    up.v = "v"
    assert_not_predicate up, :valid?, "Key should be too long"
    assert_predicate up.errors[:k], :any?
  end

  def test_value_length_valid
    up = build(:user_preference)
    up.user = create(:user)
    up.k = "k"
    up.v = "v" * 1_000_000
    assert_predicate up, :valid?
    assert up.save!
    resp = UserPreference.find(up.id)
    assert_equal "k", resp.k
    assert_equal "v" * 1_000_000, resp.v, "User preference with 1000000 v chars fails"
  end

  def test_value_length_invalid
    up = build(:user_preference)
    up.user = create(:user)
    up.k = "k"
    up.v = "v" * 1_000_001
    assert_not_predicate up, :valid?, "Value should be too long"
    assert_predicate up.errors[:v], :any?
  end
end
