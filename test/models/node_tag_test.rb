require "test_helper"

class NodeTagTest < ActiveSupport::TestCase
  def test_length_key_valid
    tag = create(:node_tag)
    (0..255).each do |i|
      tag.k = "k" * i
      assert tag.valid?
    end
  end

  def test_length_value_valid
    tag = create(:node_tag)
    (0..255).each do |i|
      tag.v = "v" * i
      assert tag.valid?
    end
  end

  def test_length_key_invalid
    tag = create(:node_tag)
    tag.k = "k" * 256
    assert !tag.valid?, "Key should be too long"
    assert tag.errors[:k].any?
  end

  def test_length_value_invalid
    tag = create(:node_tag)
    tag.v = "v" * 256
    assert !tag.valid?, "Value should be too long"
    assert tag.errors[:v].any?
  end

  def test_empty_node_tag_invalid
    tag = NodeTag.new
    assert !tag.valid?, "Empty tag should be invalid"
    assert tag.errors[:node].any?
  end

  def test_uniqueness
    existing = create(:node_tag)
    tag = NodeTag.new
    tag.node_id = existing.node_id
    tag.k = existing.k
    tag.v = existing.v
    assert tag.new_record?
    assert !tag.valid?
    assert_raise(ActiveRecord::RecordInvalid) { tag.save! }
    assert tag.new_record?
  end
end
