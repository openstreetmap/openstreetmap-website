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
    # Due to sanitisation in the view some of these that you might not 
    # expact are allowed
    # However, would they affect the xml planet dumps?
    ok = [ "Name", "'me", "he\"", "#ping", "<hr>"]
    # These need to be 3 chars in length, otherwise the length test above
    # should be used.
    bad = [ "<hr/>", "test@example.com", "s/f", "aa/", "aa;", "aa.", "aa,", "aa?", "/;.,?" ]
    ok.each do |display_name|
      user = users(:normal_user)
      user.display_name = display_name
      assert user.valid?, "#{display_name} is invalid, when it should be"
    end
    
    bad.each do |display_name|
      user = users(:normal_user)
      user.display_name = display_name
      assert !user.valid?, "#{display_name} is valid when it shouldn't be"
      assert_equal "is invalid", user.errors.on(:display_name)
    end
  end
  
  def test_friend_with
    assert_equal false, users(:normal_user).is_friends_with?(users(:second_user))
    assert_equal false, users(:normal_user).is_friends_with?(users(:inactive_user))
    assert_equal false, users(:second_user).is_friends_with?(users(:normal_user))
    assert_equal false, users(:second_user).is_friends_with?(users(:inactive_user))
    assert_equal false, users(:inactive_user).is_friends_with?(users(:normal_user))
    assert_equal false, users(:inactive_user).is_friends_with?(users(:second_user))
  end
  
  def test_users_nearby
    # second user has their data public and is close by normal user
    assert_equal [users(:second_user)], users(:normal_user).nearby
    # second_user has normal user nearby, but normal user has their data private
    assert_equal [], users(:second_user).nearby
    # inactive_user has no user nearby
    assert_equal [], users(:inactive_user).nearby
  end
  
  def test_friends_with
    # make normal user a friend of second user
    # it should be a one way friend accossitation
    assert_equal 0, Friend.count
    norm = users(:normal_user)
    sec = users(:second_user)
    friend = Friend.new
    friend.user = norm
    friend.friend_user_id = sec.id
    friend.save
    norm.clear_aggregation_cache
    norm.clear_association_cache
    sec.clear_aggregation_cache
    sec.clear_association_cache
    assert_equal [sec], norm.nearby
    assert_equal 1, norm.nearby.size
    assert_equal 1, Friend.count
    assert_equal true, norm.is_friends_with?(sec)
    assert_equal false, sec.is_friends_with?(norm)
    assert_equal false, users(:normal_user).is_friends_with?(users(:inactive_user))
    assert_equal false, users(:second_user).is_friends_with?(users(:normal_user))
    assert_equal false, users(:second_user).is_friends_with?(users(:inactive_user))
    assert_equal false, users(:inactive_user).is_friends_with?(users(:normal_user))
    assert_equal false, users(:inactive_user).is_friends_with?(users(:second_user))
    Friend.delete_all
    assert_equal 0, Friend.count
  end
end
