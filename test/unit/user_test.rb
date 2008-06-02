require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures :users

  # Replace this with your real tests.
  def test_truth
    assert true
  end
  
  def test_invalid_with_empty_attributes
    user = User.new
    assert !user.valid?
    assert user.errors.invalid?(:email)
    assert user.errors.invalid?(:pass_crypt)
    assert user.errors.invalid?(:display_name)
    assert user.errors.invalid?(:email)
    assert !user.errors.invalid?(:home_lat)
    assert !user.errors.invalid?(:home_lon)
    assert !user.errors.invalid?(:home_zoom)
  end
  
  
end
