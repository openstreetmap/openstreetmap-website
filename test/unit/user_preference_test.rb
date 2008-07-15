require File.dirname(__FILE__) + '/../test_helper'

class UserPreferenceTest < ActiveSupport::TestCase
  fixtures :users, :user_preferences

  # This checks to make sure that there are two user preferences
  # stored in the test database.
  # This test needs to be updated for every addition/deletion from
  # the fixture file
  def test_check_count
    assert_equal 2, UserPreference.count
  end

  # Checks that you cannot add a new preference, that is a duplicate
  def test_add_duplicate_preference
    up = user_preferences(:a)
    newUP = UserPreference.new
    newUP.user = users(:normal_user)
    newUP.k = up.k
    newUP.v = "some other value"
    assert_not_equal newUP.v, up.v
    assert_raise (ActiveRecord::StatementInvalid) {newUP.save}
  end
  

end
