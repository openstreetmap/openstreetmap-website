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
  
  def test_unique_display_name
    new_user = User.new(:email => "tester@openstreetmap.org",
      :active => 0,
      :pass_crypt => Digest::MD5.hexdigest('test'),
      :display_name => users(:normal_user).display_name, 
      :data_public => 1,
      :description => "desc")
    assert !new_user.save
    assert_equal ActiveRecord::Errors.default_error_messages[:taken], new_user.errors.on(:display_name)
  end
  
  def test_email_valid
    ok = %w{ a@s.com test@shaunmcdonald.me.uk hello_local@ping-d.ng test_local@openstreetmap.org test-local@example.com }
    bad = %w{ hi ht@ n@ @.com help@.me.uk help"hi.me.uk }
    
    ok.each do |name|
      user = users(:normal_user)
      user.email = name
      assert user.valid?, user.errors.full_messages
    end
    
    bad.each do |name|
      user = users(:normal_user)
      user.email = name
      assert !user.valid?, "#{name} is valid when it shouldn't be" 
    end
  end
  
  def test_display_name_length
    user = users(:normal_user)
    user.display_name = "123"
    assert user.valid?, " should allow nil display name"
    user.display_name = "12"
    assert !user.valid?, "should not allow 2 char name"
    user.display_name = ""
    assert !user.valid?
    user.display_name = nil
    # Don't understand why it isn't allowing a nil value, 
    # when the validates statements specifically allow it
    # It appears the database does not allow null values
    assert !user.valid?
  end
  
  def test_display_name_valid
    ok = [ "Name", "'me", "he\"", "#ping", "<hr>"]
    bad = [ "<hr/>", "test@example.com", "s/f", "/", ";", ".", ",", "?", "/;.,?" ]
    ok.each do |display_name|
      user = users(:normal_user)
      user.display_name = display_name
      assert user.valid?, "#{display_name} is invalid, when it should be"
    end
    
    bad.each do |display_name|
      user = users(:normal_user)
      user.display_name = display_name
      assert !user.valid?, "#{display_name} is valid when it shouldn't be"
    end
  end
end
