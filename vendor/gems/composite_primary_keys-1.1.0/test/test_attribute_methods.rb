require 'abstract_unit'
require 'fixtures/kitchen_sink'
require 'fixtures/reference_type'

class TestAttributeMethods < Test::Unit::TestCase
  fixtures :kitchen_sinks, :reference_types
  
  def test_read_attribute_with_single_key
    rt = ReferenceType.find(1)
    assert_equal(1, rt.reference_type_id)
    assert_equal('NAME_PREFIX', rt.type_label)
    assert_equal('Name Prefix', rt.abbreviation)
  end

  def test_read_attribute_with_composite_keys
    sink = KitchenSink.find(1,2)
    assert_equal(1, sink.id_1)
    assert_equal(2, sink.id_2)
    assert_equal(Date.today, sink.a_date.to_date)
    assert_equal('string', sink.a_string)
  end
end
