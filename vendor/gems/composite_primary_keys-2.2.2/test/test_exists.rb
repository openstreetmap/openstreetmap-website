require 'abstract_unit'
require 'fixtures/article'
require 'fixtures/department'

class TestExists < Test::Unit::TestCase
  fixtures :articles, :departments
  
  def test_single_key_exists_giving_id
    assert Article.exists?(1)
  end
  
  def test_single_key_exists_giving_condition
    assert Article.exists?(['name = ?', 'Article One'])
  end
  
  def test_composite_key_exists_giving_ids_as_string
    assert Department.exists?('1,1,')
  end
  
  def test_composite_key_exists_giving_ids_as_array
    assert Department.exists?([1,1])
    assert_equal(false, Department.exists?([1111,1111]))
  end
  
  def test_composite_key_exists_giving_ids_as_condition
    assert Department.exists?(['department_id = ? and location_id = ?', 1, 1])
    assert_equal(false, Department.exists?(['department_id = ? and location_id = ?', 11111, 11111]))
  end
end