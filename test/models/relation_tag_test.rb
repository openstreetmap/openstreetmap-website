require 'test_helper'

class RelationTagTest < ActiveSupport::TestCase
  api_fixtures

  def test_relation_tag_count
    assert_equal 9, RelationTag.count
  end

  def test_length_key_valid
    key = "k"
    (0..255).each do |i|
      tag = RelationTag.new
      tag.relation_id = 1
      tag.k = key*i
      tag.v = "v"
      assert tag.valid?
    end
  end

  def test_length_value_valid
    val = "v"
    (0..255).each do |i|
      tag = RelationTag.new
      tag.relation_id = 1
      tag.k = "k"
      tag.v = val*i
      assert tag.valid?
    end
  end

  def test_length_key_invalid
    ["k"*256].each do |i|
      tag = RelationTag.new
      tag.relation_id = 1
      tag.k = i
      tag.v = "v"
      assert !tag.valid?, "Key #{i} should be too long"
      assert tag.errors[:k].any?
    end
  end

  def test_length_value_invalid
    ["v"*256].each do |i|
      tag = RelationTag.new
      tag.relation_id = 1
      tag.k = "k"
      tag.v = i
      assert !tag.valid?, "Value #{i} should be too long"
      assert tag.errors[:v].any?
    end
  end

  def test_empty_tag_invalid
    tag = RelationTag.new
    assert !tag.valid?, "Empty relation tag should be invalid"
    assert tag.errors[:relation].any?
  end

  def test_uniquness
    tag = RelationTag.new
    tag.relation_id = current_relation_tags(:t1).relation_id
    tag.k = current_relation_tags(:t1).k
    tag.v = current_relation_tags(:t1).v
    assert tag.new_record?
    assert !tag.valid?
    assert_raise(ActiveRecord::RecordInvalid) {tag.save!}
    assert tag.new_record?
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
