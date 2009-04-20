require 'abstract_unit'
require 'fixtures/reference_type'
require 'fixtures/reference_code'

class TestIds < Test::Unit::TestCase
  fixtures :reference_types, :reference_codes
  
  CLASSES = {
    :single => {
      :class => ReferenceType,
      :primary_keys => [:reference_type_id],
    },
    :dual   => { 
      :class => ReferenceCode,
      :primary_keys => [:reference_type_id, :reference_code],
    },
    :dual_strs   => { 
      :class => ReferenceCode,
      :primary_keys => ['reference_type_id', 'reference_code'],
    },
  }
  
  def setup
    self.class.classes = CLASSES
  end
  
  def test_id
    testing_with do
      assert_equal @first.id, @first.ids if composite?
    end
  end
  
  def test_id_to_s
    testing_with do
      assert_equal first_id_str, @first.id.to_s
      assert_equal first_id_str, "#{@first.id}"
    end
  end
  
  def test_ids_to_s
    testing_with do
      order = @klass.primary_key.is_a?(String) ? @klass.primary_key : @klass.primary_key.join(',')
      to_test = @klass.find(:all, :order => order)[0..1].map(&:id)
      assert_equal '(1,1),(1,2)', @klass.ids_to_s(to_test) if @key_test == :dual
      assert_equal '1,1;1,2', @klass.ids_to_s(to_test, ',', ';', '', '') if @key_test == :dual
    end
  end
  
  def test_composite_where_clause
    testing_with do
      where = 'reference_codes.reference_type_id=1 AND reference_codes.reference_code=2) OR (reference_codes.reference_type_id=2 AND reference_codes.reference_code=2'
      assert_equal(where, @klass.composite_where_clause([[1, 2], [2, 2]])) if @key_test == :dual
    end
  end
  
  def test_set_ids_string
    testing_with do
      array = @primary_keys.collect {|key| 5}
      expected = composite? ? array.to_composite_keys : array.first
      @first.id = expected.to_s
      assert_equal expected, @first.id
    end
  end
  
  def test_set_ids_array
    testing_with do
      array = @primary_keys.collect {|key| 5}
      expected = composite? ? array.to_composite_keys : array.first
      @first.id = expected
      assert_equal expected, @first.id
    end
  end
  
  def test_set_ids_comp
    testing_with do
      array = @primary_keys.collect {|key| 5}
      expected = composite? ? array.to_composite_keys : array.first
      @first.id = expected
      assert_equal expected, @first.id
    end
  end
  
  def test_primary_keys
    testing_with do
      if composite?
        assert_not_nil @klass.primary_keys
        assert_equal @primary_keys.map {|key| key.to_sym}, @klass.primary_keys
        assert_equal @klass.primary_keys, @klass.primary_key
      else
        assert_not_nil @klass.primary_key
        assert_equal @primary_keys, [@klass.primary_key.to_sym]
      end
      assert_equal @primary_keys.join(','), @klass.primary_key.to_s
      # Need a :primary_keys should be Array with to_s overridden
    end
  end
end