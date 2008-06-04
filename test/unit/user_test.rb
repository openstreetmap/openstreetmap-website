require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures :users
  
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
  
  def test_unique_email
    new_user = User.new(:email => users(:normal_user).email,
      :active => 1, 
      :pass_crypt => Digest::MD5.hexdigest('test'),
      :display_name => "new user",
      :data_public => 1,
      :description => "desc")
    assert !new_user.save
    assert_equal ActiveRecord::Errors.default_error_messages[:taken], new_user.errors.on(:email)
  end
end
