# -*- coding: utf-8 -*-
require "test_helper"

class UserTest < ActiveSupport::TestCase
  include Rails::Dom::Testing::Assertions::SelectorAssertions

  api_fixtures
  fixtures :user_roles

  def test_invalid_with_empty_attributes
    user = User.new
    assert !user.valid?
    assert user.errors[:email].any?
    assert user.errors[:pass_crypt].any?
    assert user.errors[:display_name].any?
    assert user.errors[:email].any?
    assert !user.errors[:home_lat].any?
    assert !user.errors[:home_lon].any?
    assert !user.errors[:home_zoom].any?
  end

  def test_unique_email
    new_user = User.new(
      :email => users(:normal_user).email,
      :status => "active",
      :pass_crypt => Digest::MD5.hexdigest("test"),
      :display_name => "new user",
      :data_public => 1,
      :description => "desc"
    )
    assert !new_user.save
    assert new_user.errors[:email].include?("has already been taken")
  end

  def test_unique_display_name
    new_user = User.new(
      :email => "tester@openstreetmap.org",
      :status => "pending",
      :pass_crypt => Digest::MD5.hexdigest("test"),
      :display_name => users(:normal_user).display_name,
      :data_public => 1,
      :description => "desc"
    )
    assert !new_user.save
    assert new_user.errors[:display_name].include?("has already been taken")
  end

  def test_email_valid
    ok = %w(a@s.com test@shaunmcdonald.me.uk hello_local@ping-d.ng
            test_local@openstreetmap.org test-local@example.com)
    bad = %w(hi ht@ n@ @.com help@.me.uk help"hi.me.uk も対@応します
             輕觸搖晃的遊戲@ah.com も対応します@s.name)

    ok.each do |name|
      user = build(:user)
      user.email = name
      assert user.valid?(:save), user.errors.full_messages.join(",")
    end

    bad.each do |name|
      user = build(:user)
      user.email = name
      assert user.invalid?(:save), "#{name} is valid when it shouldn't be"
    end
  end

  def test_display_name_length
    user = build(:user)
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
    ok = ["Name", "'me", "he\"", "<hr>", "*ho", "\"help\"@",
          "vergrößern", "ルシステムにも対応します", "輕觸搖晃的遊戲"]
    # These need to be 3 chars in length, otherwise the length test above
    # should be used.
    bad = ["<hr/>", "test@example.com", "s/f", "aa/", "aa;", "aa.",
           "aa,", "aa?", "/;.,?", "も対応します/", "#ping",
           "foo\x1fbar", "foo\x7fbar", "foo\ufffebar", "foo\uffffbar",
           "new", "terms", "save", "confirm", "confirm-email",
           "go_public", "reset-password", "forgot-password", "suspended"]
    ok.each do |display_name|
      user = build(:user)
      user.display_name = display_name
      assert user.valid?, "#{display_name} is invalid, when it should be"
    end

    bad.each do |display_name|
      user = build(:user)
      user.display_name = display_name
      assert !user.valid?, "#{display_name} is valid when it shouldn't be"
    end
  end

  def test_friend_with
    create(:friend, :befriender => users(:normal_user), :befriendee => users(:public_user))
    assert users(:normal_user).is_friends_with?(users(:public_user))
    assert !users(:normal_user).is_friends_with?(users(:inactive_user))
    assert !users(:public_user).is_friends_with?(users(:normal_user))
    assert !users(:public_user).is_friends_with?(users(:inactive_user))
    assert !users(:inactive_user).is_friends_with?(users(:normal_user))
    assert !users(:inactive_user).is_friends_with?(users(:public_user))
  end

  def test_users_nearby
    # second user has their data public and is close by normal user
    assert_equal [users(:public_user), users(:german_user)], users(:normal_user).nearby
    # second_user has normal user nearby, but normal user has their data private
    assert_equal [users(:german_user)], users(:public_user).nearby
    # inactive_user has no user nearby
    assert_equal [], users(:inactive_user).nearby
    # north_pole_user has no user nearby, and doesn't throw exception
    assert_equal [], users(:north_pole_user).nearby
    # confirmed_user has no home location
    assert_equal [], users(:confirmed_user).nearby
  end

  def test_friends_with
    # normal user is a friend of second user
    # it should be a one way friend associatation
    norm = users(:normal_user)
    sec = users(:public_user)
    create(:friend, :befriender => norm, :befriendee => sec)
    assert_equal 1, Friend.count
    assert_equal [sec], norm.friend_users
    assert_equal 1, norm.friend_users.size
    assert_equal 1, Friend.count
    assert norm.is_friends_with?(sec)
    assert !sec.is_friends_with?(norm)
    assert !users(:normal_user).is_friends_with?(users(:inactive_user))
    assert !users(:public_user).is_friends_with?(users(:normal_user))
    assert !users(:public_user).is_friends_with?(users(:inactive_user))
    assert !users(:inactive_user).is_friends_with?(users(:normal_user))
    assert !users(:inactive_user).is_friends_with?(users(:public_user))
    # Friend.delete(friend)
    # assert_equal 0, Friend.count
  end

  def test_user_preferred_editor
    user = create(:user)
    assert_nil user.preferred_editor
    user.preferred_editor = "potlatch"
    assert_equal "potlatch", user.preferred_editor
    user.save!

    user.preferred_editor = "invalid_editor"
    assert_raise(ActiveRecord::RecordInvalid) { user.save! }
  end

  def test_visible
    assert_equal 23, User.visible.count
    assert_raise ActiveRecord::RecordNotFound do
      User.visible.find(users(:suspended_user).id)
    end
    assert_raise ActiveRecord::RecordNotFound do
      User.visible.find(users(:deleted_user).id)
    end
  end

  def test_active
    assert_equal 22, User.active.count
    assert_raise ActiveRecord::RecordNotFound do
      User.active.find(users(:inactive_user).id)
    end
    assert_raise ActiveRecord::RecordNotFound do
      User.active.find(users(:suspended_user).id)
    end
    assert_raise ActiveRecord::RecordNotFound do
      User.active.find(users(:deleted_user).id)
    end
  end

  def test_identifiable
    assert_equal 24, User.identifiable.count
    assert_raise ActiveRecord::RecordNotFound do
      User.identifiable.find(users(:normal_user).id)
    end
  end

  def test_languages
    create(:language, :code => "en")
    create(:language, :code => "de")
    create(:language, :code => "sl")

    user = users(:normal_user)
    assert_equal ["en"], user.languages
    user.languages = %w(de fr en)
    assert_equal %w(de fr en), user.languages
    user.languages = %w(fr de sl)
    assert_equal "de", user.preferred_language
    assert_equal %w(fr de sl), user.preferred_languages.map(&:to_s)
    user = users(:public_user)
    assert_equal %w(en de), user.languages
  end

  def test_visible?
    assert_equal true, users(:inactive_user).visible?
    assert_equal true, users(:normal_user).visible?
    assert_equal true, users(:confirmed_user).visible?
    assert_equal false, users(:suspended_user).visible?
    assert_equal false, users(:deleted_user).visible?
  end

  def test_active?
    assert_equal false, users(:inactive_user).active?
    assert_equal true, users(:normal_user).active?
    assert_equal true, users(:confirmed_user).active?
    assert_equal false, users(:suspended_user).active?
    assert_equal false, users(:deleted_user).active?
  end

  def test_moderator?
    assert_equal false, create(:user).moderator?
    assert_equal true, create(:moderator_user).moderator?
  end

  def test_administrator?
    assert_equal false, create(:user).administrator?
    assert_equal true, create(:administrator_user).administrator?
  end

  def test_has_role?
    assert_equal false, create(:user).has_role?("administrator")
    assert_equal false, create(:user).has_role?("moderator")
    assert_equal true, create(:administrator_user).has_role?("administrator")
    assert_equal true, create(:moderator_user).has_role?("moderator")
  end

  def test_delete
    user = create(:user, :with_home_location, :description => "foo")
    user.delete
    assert_equal "user_#{user.id}", user.display_name
    assert user.description.blank?
    assert_nil user.home_lat
    assert_nil user.home_lon
    assert_equal false, user.image.file?
    assert_equal "deleted", user.status
    assert_equal false, user.visible?
    assert_equal false, user.active?
  end

  def test_to_xml
    user = build(:user, :with_home_location)
    xml = user.to_xml
    assert_select Nokogiri::XML::Document.parse(xml.to_s), "user" do
      assert_select "[display_name=?]", user.display_name
      assert_select "[account_created=?]", user.creation_time.xmlschema
      assert_select "home[lat=?][lon=?][zoom=?]", user.home_lat.to_s, user.home_lon.to_s, user.home_zoom.to_s
    end
  end

  def test_to_xml_node
    user = build(:user, :with_home_location)
    xml = user.to_xml_node
    assert_select Nokogiri::XML::DocumentFragment.parse(xml.to_s), "user" do
      assert_select "[display_name=?]", user.display_name
      assert_select "[account_created=?]", user.creation_time.xmlschema
      assert_select "home[lat=?][lon=?][zoom=?]", user.home_lat.to_s, user.home_lon.to_s, user.home_zoom.to_s
    end
  end
end
