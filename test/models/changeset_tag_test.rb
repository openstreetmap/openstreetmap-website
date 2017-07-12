require "test_helper"

class ChangesetTagTest < ActiveSupport::TestCase
  def test_length_key_valid
    changeset = create(:changeset)

    key = "k"
    (0..255).each do |i|
      tag = ChangesetTag.new
      tag.changeset_id = changeset.id
      tag.k = key * i
      tag.v = "v"
      assert tag.valid?
    end
  end

  def test_length_value_valid
    changeset = create(:changeset)

    val = "v"
    (0..255).each do |i|
      tag = ChangesetTag.new
      tag.changeset_id = changeset.id
      tag.k = "k"
      tag.v = val * i
      assert tag.valid?
    end
  end

  def test_length_key_invalid
    ["k" * 256].each do |k|
      tag = ChangesetTag.new
      tag.changeset_id = 1
      tag.k = k
      tag.v = "v"
      assert !tag.valid?, "Key #{k} should be too long"
      assert tag.errors[:k].any?
    end
  end

  def test_length_value_invalid
    ["v" * 256].each do |v|
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
    existing = create(:changeset_tag)
    tag = ChangesetTag.new
    tag.changeset_id = existing.changeset_id
    tag.k = existing.k
    tag.v = existing.v
    assert tag.new_record?
    assert !tag.valid?
    assert_raise(ActiveRecord::RecordInvalid) { tag.save! }
    assert tag.new_record?
  end
end
