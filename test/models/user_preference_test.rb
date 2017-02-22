require "test_helper"

class UserPreferenceTest < ActiveSupport::TestCase
  api_fixtures

  # Checks that you cannot add a new preference, that is a duplicate
  def test_add_duplicate_preference
    up = create(:user_preference)
    new_up = UserPreference.new
    new_up.user = up.user
    new_up.k = up.k
    new_up.v = "some other value"
    assert_not_equal new_up.v, up.v
    assert_raise(ActiveRecord::RecordNotUnique) { new_up.save }
  end

  def test_check_valid_length
    key = "k"
    val = "v"
    (1..255).each do |i|
      up = UserPreference.new
      up.user = users(:normal_user)
      up.k = key * i
      up.v = val * i
      assert up.valid?
      assert up.save!
      resp = UserPreference.find(up.id)
      assert_equal key * i, resp.k, "User preference with #{i} #{key} chars (i.e. #{key.length * i} bytes) fails"
      assert_equal val * i, resp.v, "User preference with #{i} #{val} chars (i.e. #{val.length * i} bytes) fails"
    end
  end

  def test_check_invalid_length
    key = "k"
    val = "v"
    [0, 256].each do |i|
      up = UserPreference.new
      up.user = users(:normal_user)
      up.k = key * i
      up.v = val * i
      assert_equal false, up.valid?
      assert_raise(ActiveRecord::RecordInvalid) { up.save! }
    end
  end
end
