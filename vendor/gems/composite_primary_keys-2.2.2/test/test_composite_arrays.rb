require 'abstract_unit'
require 'fixtures/reference_type'
require 'fixtures/reference_code'

class CompositeArraysTest < Test::Unit::TestCase

  def test_new_primary_keys
    keys = CompositePrimaryKeys::CompositeKeys.new
    assert_not_nil keys
    assert_equal '', keys.to_s
    assert_equal '', "#{keys}"
  end

  def test_initialize_primary_keys
    keys = CompositePrimaryKeys::CompositeKeys.new([1,2,3])
    assert_not_nil keys
    assert_equal '1,2,3', keys.to_s
    assert_equal '1,2,3', "#{keys}"
  end
  
  def test_to_composite_keys
    keys = [1,2,3].to_composite_keys
    assert_equal CompositePrimaryKeys::CompositeKeys, keys.class
    assert_equal '1,2,3', keys.to_s
  end

  def test_new_ids
    keys = CompositePrimaryKeys::CompositeIds.new
    assert_not_nil keys
    assert_equal '', keys.to_s
    assert_equal '', "#{keys}"
  end

  def test_initialize_ids
    keys = CompositePrimaryKeys::CompositeIds.new([1,2,3])
    assert_not_nil keys
    assert_equal '1,2,3', keys.to_s
    assert_equal '1,2,3', "#{keys}"
  end
  
  def test_to_composite_ids
    keys = [1,2,3].to_composite_ids
    assert_equal CompositePrimaryKeys::CompositeIds, keys.class
    assert_equal '1,2,3', keys.to_s
  end
  
  def test_flatten
    keys = [CompositePrimaryKeys::CompositeIds.new([1,2,3]), CompositePrimaryKeys::CompositeIds.new([4,5,6])]
    assert_equal 6, keys.flatten.size
  end
end