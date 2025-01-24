require "test_helper"

class UserTest < ActiveSupport::TestCase
  include Rails::Dom::Testing::Assertions::SelectorAssertions

  def test_invalid_with_empty_attributes
    user = build(:user, :email => nil,
                        :pass_crypt => nil,
                        :display_name => nil,
                        :home_lat => nil,
                        :home_lon => nil,
                        :home_zoom => nil)
    assert_not_predicate user, :valid?
    assert_predicate user.errors[:email], :any?
    assert_predicate user.errors[:pass_crypt], :any?
    assert_predicate user.errors[:display_name], :any?
    assert_predicate user.errors[:home_lat], :none?
    assert_predicate user.errors[:home_lon], :none?
    assert_predicate user.errors[:home_zoom], :none?
  end

  def test_unique_email
    existing_user = create(:user)
    new_user = build(:user, :email => existing_user.email)
    assert_not new_user.save
    assert_includes new_user.errors[:email], "has already been taken"
  end

  def test_unique_display_name
    create(:user, :display_name => "H\u{e9}nryIV")

    %W[H\u{e9}nryIV he\u{301}nryiv H\u{c9}nry\u2163 he\u{301}nry\u2173].each do |name|
      new_user = build(:user, :display_name => name)
      assert_not new_user.save
      assert_includes new_user.errors[:display_name], "has already been taken"
    end
  end

  def test_email_valid
    ok = %w[a@s.com test@shaunmcdonald.me.uk hello_local@ping-d.ng
            test_local@openstreetmap.org test-local@example.com]
    bad = %w[hi ht@ n@ @.com help@.me.uk help"hi.me.uk も対@応します
             輕觸搖晃的遊戲@ah.com も対応します@s.name]

    ok.each do |name|
      user = build(:user)
      user.email = name
      assert user.valid?(:save), "#{name} isn't valid when it should be"
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
    assert_predicate user, :valid?, "should allow 3 char name name"
    user.display_name = "12"
    assert_not_predicate user, :valid?, "should not allow 2 char name"
    user.display_name = ""
    assert_not_predicate user, :valid?, "should not allow blank/0 char name"
    user.display_name = nil
    assert_not_predicate user, :valid?, "should not allow nil value"
  end

  def test_display_name_width
    user = build(:user)
    user.display_name = "123"
    assert_predicate user, :valid?, "should allow 3 column name name"
    user.display_name = "12"
    assert_not_predicate user, :valid?, "should not allow 2 column name"
    user.display_name = "1\u{200B}2"
    assert_not_predicate user, :valid?, "should not allow 2 column name"
    user.display_name = "\u{200B}\u{200B}\u{200B}"
    assert_not_predicate user, :valid?, "should not allow 0 column name"
  end

  def test_display_name_valid
    # Due to sanitisation in the view some of these that you might not
    # expect are allowed
    # However, would they affect the xml planet dumps?
    ok = ["Name", "'me", "he\"", "<hr>", "*ho", "\"help\"@",
          "vergrößern", "ルシステムにも対応します", "輕觸搖晃的遊戲", "space space"]
    # These need to be 3 chars in length, otherwise the length test above
    # should be used.
    bad = ["<hr/>", "test@example.com", "s/f", "aa/", "aa;", "aa.",
           "aa,", "aa?", "/;.,?", "も対応します/", "#ping",
           "foo\x1fbar", "foo\x7fbar", "foo\ufffebar", "foo\uffffbar",
           "new", "terms", "save", "confirm", "confirm-email",
           "go_public", "reset-password", "forgot-password", "suspended",
           "trailing whitespace ", " leading whitespace"]
    ok.each do |display_name|
      user = build(:user)
      user.display_name = display_name
      assert_predicate user, :valid?, "#{display_name} is invalid, when it should be"
    end

    bad.each do |display_name|
      user = build(:user)
      user.display_name = display_name
      assert_not_predicate user, :valid?, "#{display_name} is valid when it shouldn't be"
    end
  end

  def test_display_name_user_id_new
    existing_user = create(:user)
    user = build(:user)

    user.display_name = "user_#{existing_user.id}"
    assert_not_predicate user, :valid?, "user_<id> name is valid for existing user id when it shouldn't be"

    user.display_name = "user_#{existing_user.id + 1}"
    assert_not_predicate user, :valid?, "user_<id> name is valid for new user id when it shouldn't be"
  end

  def test_display_name_user_id_rename
    existing_user = create(:user)
    user = create(:user)

    user.display_name = "user_#{existing_user.id}"
    assert_not_predicate user, :valid?, "user_<id> name is valid for existing user id when it shouldn't be"

    user.display_name = "user_#{user.id}"
    assert_predicate user, :valid?, "user_<id> name is invalid for own id, when it should be"
  end

  def test_display_name_user_id_unchanged_is_valid
    user = build(:user, :display_name => "user_0")
    user.save(:validate => false)
    user.reload

    assert_predicate user, :valid?, "user_0 display_name is invalid but it hasn't been changed"
  end

  def test_follows
    alice = create(:user, :active)
    bob = create(:user, :active)
    charlie = create(:user, :active)
    create(:follow, :follower => alice, :following => bob)

    assert alice.follows?(bob)
    assert_not alice.follows?(charlie)
    assert_not bob.follows?(alice)
    assert_not bob.follows?(charlie)
    assert_not charlie.follows?(bob)
    assert_not charlie.follows?(alice)
  end

  def test_users_nearby
    alice = create(:user, :active, :home_lat => 51.0, :home_lon => 1.0, :data_public => false)
    bob = create(:user, :active, :home_lat => 51.1, :home_lon => 1.0, :data_public => true)
    charlie = create(:user, :active, :home_lat => 51.1, :home_lon => 1.1, :data_public => true)
    david = create(:user, :active, :home_lat => 10.0, :home_lon => -123.0, :data_public => true)
    _edward = create(:user, :suspended, :home_lat => 10.0, :home_lon => -123.0, :data_public => true)
    south_pole_user = create(:user, :active, :home_lat => -90.0, :home_lon => 0.0, :data_public => true)
    vagrant_user = create(:user, :active, :home_lat => nil, :home_lon => nil, :data_public => true)

    # bob and charlie are both near alice
    assert_equal [bob, charlie], alice.nearby
    # charlie and alice are both near bob, but alice has their data private
    assert_equal [charlie], bob.nearby
    # david has no user nearby, since edward is not active
    assert_empty david.nearby
    # south_pole_user has no user nearby, and doesn't throw exception
    assert_empty south_pole_user.nearby
    # vagrant_user has no home location
    assert_empty vagrant_user.nearby
  end

  def test_friends
    norm = create(:user, :active)
    sec = create(:user, :active)
    create(:follow, :follower => norm, :following => sec)

    assert_equal [sec], norm.followings
    assert_equal 1, norm.followings.size

    assert_empty sec.followings
    assert_equal 0, sec.followings.size
  end

  def test_user_preferred_editor
    user = create(:user)
    assert_nil user.preferred_editor
    user.preferred_editor = "id"
    assert_equal "id", user.preferred_editor
    user.save!

    user.preferred_editor = "invalid_editor"
    assert_raise(ActiveRecord::RecordInvalid) { user.save! }
  end

  def test_visible
    pending = create(:user, :pending)
    active = create(:user, :active)
    confirmed = create(:user, :confirmed)
    suspended = create(:user, :suspended)
    deleted = create(:user, :deleted)

    assert User.visible.find(pending.id)
    assert User.visible.find(active.id)
    assert User.visible.find(confirmed.id)
    assert_raise ActiveRecord::RecordNotFound do
      User.visible.find(suspended.id)
    end
    assert_raise ActiveRecord::RecordNotFound do
      User.visible.find(deleted.id)
    end
  end

  def test_active
    pending = create(:user, :pending)
    active = create(:user, :active)
    confirmed = create(:user, :confirmed)
    suspended = create(:user, :suspended)
    deleted = create(:user, :deleted)

    assert User.active.find(active.id)
    assert User.active.find(confirmed.id)
    assert_raise ActiveRecord::RecordNotFound do
      User.active.find(pending.id)
    end
    assert_raise ActiveRecord::RecordNotFound do
      User.active.find(suspended.id)
    end
    assert_raise ActiveRecord::RecordNotFound do
      User.active.find(deleted.id)
    end
  end

  def test_identifiable
    public_user = create(:user, :data_public => true)
    private_user = create(:user, :data_public => false)

    assert User.identifiable.find(public_user.id)
    assert_raise ActiveRecord::RecordNotFound do
      User.identifiable.find(private_user.id)
    end
  end

  def test_languages
    create(:language, :code => "en")
    create(:language, :code => "de")
    create(:language, :code => "sl")

    user = create(:user, :languages => ["en"])
    assert_equal ["en"], user.languages
    user.languages = %w[de fr en]
    assert_equal %w[de fr en], user.languages
    user.languages = %w[fr de sl]
    assert_equal "de", user.preferred_language
    assert_equal %w[fr de sl], user.preferred_languages.map(&:to_s)
    user = create(:user, :languages => %w[en de])
    assert_equal %w[en de], user.languages
  end

  def test_visible?
    assert_predicate build(:user, :pending), :visible?
    assert_predicate build(:user, :active), :visible?
    assert_predicate build(:user, :confirmed), :visible?
    assert_not_predicate build(:user, :suspended), :visible?
    assert_not_predicate build(:user, :deleted), :visible?
  end

  def test_active?
    assert_not_predicate build(:user, :pending), :active?
    assert_predicate build(:user, :active), :active?
    assert_predicate build(:user, :confirmed), :active?
    assert_not_predicate build(:user, :suspended), :active?
    assert_not_predicate build(:user, :deleted), :active?
  end

  def test_moderator?
    assert_not_predicate create(:user), :moderator?
    assert_predicate create(:moderator_user), :moderator?
  end

  def test_administrator?
    assert_not_predicate create(:user), :administrator?
    assert_predicate create(:administrator_user), :administrator?
  end

  def test_role?
    assert_not create(:user).role?("administrator")
    assert_not create(:user).role?("moderator")
    assert create(:administrator_user).role?("administrator")
    assert create(:moderator_user).role?("moderator")
  end

  def test_soft_destroy
    user = create(:user, :with_home_location, :description => "foo")
    user.soft_destroy
    assert_equal "user_#{user.id}", user.display_name
    assert_predicate user.description, :blank?
    assert_nil user.home_lat
    assert_nil user.home_lon
    assert_not_predicate user.avatar, :attached?
    assert_equal "deleted", user.status
    assert_not_predicate user, :visible?
    assert_not_predicate user, :active?
  end

  def test_soft_destroy_revokes_oauth2_tokens
    user = create(:user)
    oauth_access_token = create(:oauth_access_token, :user => user)
    assert_equal 1, user.access_tokens.not_expired.count

    user.soft_destroy

    assert_equal 0, user.access_tokens.not_expired.count
    oauth_access_token.reload
    assert_predicate oauth_access_token, :revoked?
  end

  def test_deletion_allowed_when_no_changesets
    with_user_account_deletion_delay(10000) do
      user = create(:user)
      assert_predicate user, :deletion_allowed?
    end
  end

  def test_deletion_allowed_without_delay
    with_user_account_deletion_delay(nil) do
      user = create(:user)
      create(:changeset, :user => user)
      user.reload
      assert_predicate user, :deletion_allowed?
    end
  end

  def test_deletion_allowed_past_delay
    with_user_account_deletion_delay(10) do
      user = create(:user)
      create(:changeset, :user => user, :created_at => Time.now.utc - 12.hours, :closed_at => Time.now.utc - 10.hours)
      user.reload
      assert_predicate user, :deletion_allowed?
    end
  end

  def test_deletion_allowed_during_delay
    with_user_account_deletion_delay(10) do
      user = create(:user)
      create(:changeset, :user => user, :created_at => Time.now.utc - 11.hours, :closed_at => Time.now.utc - 9.hours)
      user.reload
      assert_not_predicate user, :deletion_allowed?
      assert_equal Time.now.utc + 1.hour, user.deletion_allowed_at
    end
  end

  def test_deletion_allowed_past_zero_delay
    with_user_account_deletion_delay(0) do
      user = create(:user)
      create(:changeset, :user => user, :created_at => Time.now.utc, :closed_at => Time.now.utc + 1.hour)
      travel 90.minutes do
        user.reload
        assert_predicate user, :deletion_allowed?
      end
    end
  end

  def test_deletion_allowed_during_zero_delay
    with_user_account_deletion_delay(0) do
      user = create(:user)
      create(:changeset, :user => user, :created_at => Time.now.utc, :closed_at => Time.now.utc + 1.hour)
      travel 30.minutes do
        user.reload
        assert_not_predicate user, :deletion_allowed?
        assert_equal Time.now.utc + 30.minutes, user.deletion_allowed_at
      end
    end
  end
end
