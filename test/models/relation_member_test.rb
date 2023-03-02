require "test_helper"

class RelationMemberTest < ActiveSupport::TestCase
  def test_role_with_invalid_characters
    invalid = ["\x7f<hr/>", "test@example.com\x0e-", "s/\x1ff", "aa/\ufffe",
               "aa\x0b-,", "aa?\x08", "/;\uffff.,?", "\x0c#ping",
               "foo\x1fbar", "foo\x7fbar", "foo\ufffebar", "foo\uffffbar"]
    relation = create(:relation)
    node = create(:node)
    invalid.each do |r|
      member = build(:relation_member, :relation => relation, :member => node, :member_role => r)
      assert_not member.valid?, "'#{r}' should not be valid"
      assert_predicate member.errors[:member_role], :any?
    end
  end

  def test_role_too_long
    relation = create(:relation)
    node = create(:node)
    member = build(:relation_member, :relation => relation, :member => node, :member_role => "r" * 256)
    assert_not member.valid?, "Role should be too long"
    assert_predicate member.errors[:member_role], :any?
  end
end
