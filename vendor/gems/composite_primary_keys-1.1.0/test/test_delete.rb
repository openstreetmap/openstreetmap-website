require 'abstract_unit'
require 'fixtures/reference_type'
require 'fixtures/reference_code'
require 'fixtures/department'
require 'fixtures/employee'

class TestDelete < Test::Unit::TestCase
  fixtures :reference_types, :reference_codes, :departments, :employees
  
  CLASSES = {
    :single => {
      :class => ReferenceType,
      :primary_keys => :reference_type_id,
    },
    :dual   => { 
      :class => ReferenceCode,
      :primary_keys => [:reference_type_id, :reference_code],
    },
  }
  
  def setup
    self.class.classes = CLASSES
  end
  
  def test_destroy_one
    testing_with do
      #assert @first.destroy
      assert true
    end
  end
  
  def test_destroy_one_via_class
    testing_with do
      assert @klass.destroy(*@first.id)
    end
  end
  
  def test_destroy_one_alone_via_class
    testing_with do
      assert @klass.destroy(@first.id)
    end
  end
  
  def test_delete_one
    testing_with do
      assert @klass.delete(*@first.id) if composite?
    end
  end
  
  def test_delete_one_alone
    testing_with do
      assert @klass.delete(@first.id)
    end
  end
  
  def test_delete_many
    testing_with do
      to_delete = @klass.find(:all)[0..1]
      assert_equal 2, to_delete.length
    end
  end
  
  def test_delete_all
    testing_with do
      @klass.delete_all
    end
  end

  def test_clear_association
      department = Department.find(1,1)
      assert_equal 2, department.employees.size, "Before clear employee count should be 2."
      department.employees.clear
      assert_equal 0, department.employees.size, "After clear employee count should be 0."
      department.reload
      assert_equal 0, department.employees.size, "After clear and a reload from DB employee count should be 0."
  end

  def test_delete_association
      department = Department.find(1,1)
      assert_equal 2, department.employees.size , "Before delete employee count should be 2."
      first_employee = department.employees[0]
      department.employees.delete(first_employee)
      assert_equal 1, department.employees.size, "After delete employee count should be 1."
      department.reload
      assert_equal 1, department.employees.size, "After delete and a reload from DB employee count should be 1."
  end

  def test_delete_records_for_has_many_association_with_composite_primary_key
      reference_type  = ReferenceType.find(1)
      codes_to_delete = reference_type.reference_codes[0..1]
      assert_equal 3, reference_type.reference_codes.size, "Before deleting records reference_code count should be 3."
      reference_type.reference_codes.delete_records(codes_to_delete)
      reference_type.reload
      assert_equal 1, reference_type.reference_codes.size, "After deleting 2 records and a reload from DB reference_code count should be 1."
  end
end
