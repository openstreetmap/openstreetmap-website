require "test_helper"

class RelationTagTest < ActiveSupport::TestCase
  def test_length_key_valid
    tag = create(:relation_tag)
    [0, 255].each do |i|
      tag.k = "k" * i
      assert_predicate tag, :valid?
    end
  end

  def test_length_value_valid
    tag = create(:relation_tag)
    [0, 255].each do |i|
      tag.v = "v" * i
      assert_predicate tag, :valid?
    end
  end

  def test_length_key_invalid
    tag = create(:relation_tag)
    tag.k = "k" * 256
    assert_not tag.valid?, "Key should be too long"
    assert_predicate tag.errors[:k], :any?
  end

  def test_length_value_invalid
    tag = create(:relation_tag)
    tag.v = "v" * 256
    assert_not tag.valid?, "Value should be too long"
    assert_predicate tag.errors[:v], :any?
  end

  def test_orphaned_tag_invalid
    tag = create(:relation_tag)
    tag.relation = nil
    assert_not tag.valid?, "Orphaned tag should be invalid"
    assert_predicate tag.errors[:relation], :any?
  end

  def test_uniqueness
    existing = create(:relation_tag)
    tag = build(:relation_tag, :relation => existing.relation, :k => existing.k, :v => existing.v)
    assert_predicate tag, :new_record?
    assert_not tag.valid?
    assert_raise(ActiveRecord::RecordInvalid) { tag.save! }
    assert_predicate tag, :new_record?
  end

  ##
  # test that tags can be updated and saved uniquely, i.e: tag.save!
  # only affects the single tag that the activerecord object
  # represents. this amounts to testing that the primary key is
  # unique.
  #
  # Commenting this out - I attempted to fix it, but composite primary keys
  # wasn't playing nice with the column already called :id. Seemed to be
  # impossible to have validations on the :id column. If someone knows better
  # please fix, otherwise this test is shelved.
  #
  # def test_update
  #   v = "probably unique string here 3142592654"
  #   assert_equal 0, RelationTag.count(:conditions => ['v=?', v])

  #   # make sure we select a tag on a relation which has more than one tag
  #   id = current_relations(:multi_tag_relation).relation_id
  #   tag = RelationTag.find(:first, :conditions => ["id = ?", id])
  #   tag.v = v
  #   tag.save!

  #   assert_equal 1, RelationTag.count(:conditions => ['v=?', v])
  # end
end
