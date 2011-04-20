# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  api_fixtures
  fixtures :friends

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
      :status => "active", 
      :pass_crypt => Digest::MD5.hexdigest('test'),
      :display_name => "new user",
      :data_public => 1,
      :description => "desc")
    assert !new_user.save
    assert_equal "has already been taken", new_user.errors.on(:email)
  end
  
  def test_unique_display_name
    new_user = User.new(:email => "tester@openstreetmap.org",
      :status => "pending",
      :pass_crypt => Digest::MD5.hexdigest('test'),
      :display_name => users(:normal_user).display_name, 
      :data_public => 1,
      :description => "desc")
    assert !new_user.save
    assert_equal "has already been taken", new_user.errors.on(:display_name)
  end
  
  def test_email_valid
    ok = %w{ a@s.com test@shaunmcdonald.me.uk hello_local@ping-d.ng 
    test_local@openstreetmap.org test-local@example.com }
    bad = %w{ hi ht@ n@ @.com help@.me.uk help"hi.me.uk も対@応します
    輕觸搖晃的遊戲@ah.com も対応します@s.name }
    
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
    ok = [ "Name", "'me", "he\"", "#ping", "<hr>", "*ho", "\"help\"@", 
           "vergrößern", "ルシステムにも対応します", "輕觸搖晃的遊戲" ]
    # These need to be 3 chars in length, otherwise the length test above
    # should be used.
    bad = [ "<hr/>", "test@example.com", "s/f", "aa/", "aa;", "aa.",
            "aa,", "aa?", "/;.,?", "も対応します/" ]
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
    assert_equal true, users(:normal_user).is_friends_with?(users(:public_user))
    assert_equal false, users(:normal_user).is_friends_with?(users(:inactive_user))
    assert_equal false, users(:public_user).is_friends_with?(users(:normal_user))
    assert_equal false, users(:public_user).is_friends_with?(users(:inactive_user))
    assert_equal false, users(:inactive_user).is_friends_with?(users(:normal_user))
    assert_equal false, users(:inactive_user).is_friends_with?(users(:public_user))
  end
  
  def test_users_nearby
    # second user has their data public and is close by normal user
    assert_equal [users(:public_user)], users(:normal_user).nearby
    # second_user has normal user nearby, but normal user has their data private
    assert_equal [], users(:public_user).nearby
    # inactive_user has no user nearby
    assert_equal [], users(:inactive_user).nearby
  end
  
  def test_friends_with
    # normal user is a friend of second user
    # it should be a one way friend accossitation
    assert_equal 1, Friend.count
    norm = users(:normal_user)
    sec = users(:public_user)
    #friend = Friend.new
    #friend.befriender = norm
    #friend.befriendee = sec
    #friend.save
    assert_equal [sec], norm.nearby
    assert_equal 1, norm.nearby.size
    assert_equal 1, Friend.count
    assert_equal true, norm.is_friends_with?(sec)
    assert_equal false, sec.is_friends_with?(norm)
    assert_equal false, users(:normal_user).is_friends_with?(users(:inactive_user))
    assert_equal false, users(:public_user).is_friends_with?(users(:normal_user))
    assert_equal false, users(:public_user).is_friends_with?(users(:inactive_user))
    assert_equal false, users(:inactive_user).is_friends_with?(users(:normal_user))
    assert_equal false, users(:inactive_user).is_friends_with?(users(:public_user))
    #Friend.delete(friend)
    #assert_equal 0, Friend.count
  end

  def test_user_preferred_editor
    user = users(:normal_user)
    assert_equal nil, user.preferred_editor
    user.preferred_editor = "potlatch"
    assert_equal "potlatch", user.preferred_editor
    user.save!

    user.preferred_editor = "invalid_editor"
    assert_raise(ActiveRecord::RecordInvalid) { user.save! }
  end
end
