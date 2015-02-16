require 'test_helper'

class ChangesetTagTest < ActiveSupport::TestCase
  api_fixtures

  def test_changeset_tag_count
    assert_equal 2, ChangesetTag.count
  end

  def test_length_key_valid
    key = "k"
    (0..255).each do |i|
      tag = ChangesetTag.new
      tag.changeset_id = 1
      tag.k = key*i
      tag.v = "v"
      assert tag.valid?
    end
  end

  def test_length_value_valid
    val = "v"
    (0..255).each do |i|
      tag = ChangesetTag.new
      tag.changeset_id = 1
      tag.k = "k"
      tag.v = val*i
      assert tag.valid?
    end
  end

  def test_length_key_invalid
    ["k"*256].each do |k|
      tag = ChangesetTag.new
      tag.changeset_id = 1
      tag.k = k
      tag.v = "v"
      assert !tag.valid?, "Key #{k} should be too long"
      assert tag.errors[:k].any?
    end
  end

  def test_length_value_invalid
    ["v"*256].each do |v|
      tag = ChangesetTag.new
      tag.changeset_id = 1
      tag.k = "k"
      tag.v = v
      assert !tag.valid?, "Value #{v} should be too long"
      assert tag.errors[:v].any?
    end
  end

  def test_empty_tag_invalid
    tag = ChangesetTag.new
    assert !tag.valid?, "Empty tag should be invalid"
    assert tag.errors[:changeset].any?
  end

  def test_uniqueness
    tag = ChangesetTag.new
    tag.changeset_id = changeset_tags(:changeset_1_tag_1).changeset_id
    tag.k = changeset_tags(:changeset_1_tag_1).k
    tag.v = changeset_tags(:changeset_1_tag_1).v
    assert tag.new_record?
    assert !tag.valid?
    assert_raise(ActiveRecord::RecordInvalid) {tag.save!}
    assert tag.new_record?
  end
end
