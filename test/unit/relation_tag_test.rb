require File.dirname(__FILE__) + '/../test_helper'

class RelationTagTest < Test::Unit::TestCase
  api_fixtures
  
  def test_relation_tag_count
    assert_equal 7, RelationTag.count
  end
  
  def test_length_key_valid
    key = "k"
    (0..255).each do |i|
      tag = RelationTag.new
      tag.id = 1
      tag.k = key*i
      tag.v = "v"
      assert_valid tag
    end
  end
  
  def test_length_value_valid
    val = "v"
    (0..255).each do |i|
      tag = RelationTag.new
      tag.id = 1
      tag.k = "k"
      tag.v = val*i
      assert_valid tag
    end
  end
  
  def test_length_key_invalid
    ["k"*256].each do |i|
      tag = RelationTag.new
      tag.id = 1
      tag.k = i
      tag.v = "v"
      assert !tag.valid?, "Key #{i} should be too long"
      assert tag.errors.invalid?(:k)
    end
  end
  
  def test_length_value_invalid
    ["v"*256].each do |i|
      tag = RelationTag.new
      tag.id = 1
      tag.k = "k"
      tag.v = i
      assert !tag.valid?, "Value #{i} should be too long"
      assert tag.errors.invalid?(:v)
    end
  end
  
  def test_empty_tag_invalid
    tag = RelationTag.new
    assert !tag.valid?, "Empty relation tag should be invalid"
    assert tag.errors.invalid?(:id)
  end
  
  def test_uniquness
    tag = RelationTag.new
    tag.id = current_relation_tags(:t1).id
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
  def test_update
    v = "probably unique string here 3142592654"
    assert_equal 0, RelationTag.count(:conditions => ['v=?', v])

    tag = RelationTag.find(:first)
    tag.v = v
    tag.save!

    assert_equal 1, RelationTag.count(:conditions => ['v=?', v])
  end
end
