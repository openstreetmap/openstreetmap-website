require 'abstract_unit'
require 'fixtures/reference_type'
require 'fixtures/reference_code'

class TestUpdate < Test::Unit::TestCase
  fixtures :reference_types, :reference_codes
  
  CLASSES = {
    :single => {
      :class => ReferenceType,
      :primary_keys => :reference_type_id,
      :update => { :description => 'RT Desc' },
    },
    :dual   => { 
      :class => ReferenceCode,
      :primary_keys => [:reference_type_id, :reference_code],
      :update => { :description => 'RT Desc' },
    },
  }
  
  def setup
    self.class.classes = CLASSES
  end
  
  def test_setup
    testing_with do
      assert_not_nil @klass_info[:update]
    end
  end
  
  def test_update_attributes
    testing_with do
      assert @first.update_attributes(@klass_info[:update])
      assert @first.reload
      @klass_info[:update].each_pair do |attr_name, new_value|
        assert_equal new_value, @first[attr_name], "Attribute #{attr_name} is incorrect"
      end
    end
  end
end