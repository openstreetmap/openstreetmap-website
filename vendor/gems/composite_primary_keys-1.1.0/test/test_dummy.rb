require 'abstract_unit'
require 'fixtures/reference_type'
require 'fixtures/reference_code'

class TestDummy < Test::Unit::TestCase
  fixtures :reference_types, :reference_codes
  
  classes = {
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
    self.class.classes = classes
  end
  
  def test_truth
    testing_with do
      assert true
    end
  end
end